# Self-hosted Git on kruppe (Forgejo) + R2 backups — Design

- **Date:** 2026-07-09
- **Status:** Approved design, pending implementation plan
- **Repos touched:** `nixos-config` (compute on kruppe), `~/dev/infra` (cloud resources)

## Background & why not Tangled

The original idea was a **Tangled** knot (ATProto git). Investigation killed it for
this use case:

- Tangled has **no private-repo / access-control feature** — repos are public by
  default, no visibility setting, no encryption.
- Root cause is protocol-level: **all ATProto PDS records are 100% public** — every
  PDS exposes public repo-download endpoints and the firehose broadcasts every
  create/update/delete with no auth. Private namespaces are *planned upstream*, not
  shipped.
- Tangled stores **issues/PRs as PDS records → public**, and repo code on the knot is
  public too. Self-hosting a PDS would only mean self-hosting *public* data.

Since a hard requirement is **migrating private GitHub repos** (with private issues/PRs),
Tangled is disqualified. Chosen replacement: **Forgejo** — lightweight, private repos,
non-profit community governance, built-in GitHub importer, first-class NixOS module.

(Tangled remains attractive for *public/open-source* repos later; out of scope here.)

## Goals

1. Self-hosted git server on **kruppe**, reachable publicly at `git.mattys.cloud`
   (kruppe already serves `mattys.cloud`; apex A → `87.121.93.120`).
2. **Private** repos, issues, and PRs — nothing leaves kruppe.
3. Migrate existing **private GitHub repos** (code + issues + PRs + wiki + releases).
4. **Data safety**: encrypted, scheduled off-site backups to **Cloudflare R2**, with
   point-in-time restore.
5. Cloud resources provisioned through the existing **`~/dev/infra`** source-of-truth
   (Route53 DNS, R2 bucket, scoped R2 token) — the "hybrid" model: infra owns cloud,
   nixos-config owns compute.

## Non-goals

- Self-hosted ATProto PDS (deferred, separate project).
- Tangled knot (dropped for this use case).
- Built-in CI/CD, container registry, pages. **A Forgejo Actions runner is deferred to
  the companion `matthewtapps.com` static-hosting spec**, which needs it; it extends this
  platform but is out of scope here.
- Postgres (SQLite is sufficient for single-user; revisit only if scale demands).

## Architecture (Hybrid: infra owns cloud, nixos-config owns compute)

```
                     Route53 (mattys.cloud, in infra tofu)
                     git.mattys.cloud  CNAME -> mattys.cloud
                                   |
   internet ── 443 (public) ──────┐        22 NEVER public
   tailnet/LAN ── 22 ────────────┐│        (edge forwards 80/443 only)
                                 ▼▼
              ┌──────────── kruppe ────────────────────────────┐
              │  nginx (reverse-proxy.nix)  [public 443]        │
              │    git.mattys.cloud -> 127.0.0.1:3000  (HTTPS)  │
              │  system OpenSSH :22  [tailscale0 + LAN only]     │
              │    git-SSH via forgejo user (forced command)    │
              │  tailscaled (declarative, authKeyFile <- sops)  │
              │  services.forgejo  (SQLite, /var/lib/forgejo)   │
              │  restic timer ── pre: sqlite3 .backup ──┐       │
              └─────────────────────────────────────────┼──────┘
                                                         ▼
                          Cloudflare R2  s3:.../forgejo-backups
                          (bucket + scoped token, in infra tofu)
                          creds -> secrets/kruppe.yaml (sops)
```

### Component 1 — infra repo (OpenTofu), cloud resources only

Rationale for hybrid: kruppe is a home-server "pet" in nixos-config, **not** an
infra-managed DigitalOcean droplet ("cattle"). It has no `host_key` / age recipient in
infra's `local.services`. So we provision only its *cloud* resources here and do **not**
fake a droplet-shaped service entry.

1. **DNS** — in `tofu/dns_mattys_cloud.tf`, add `git.mattys.cloud` as a `CNAME` →
   `mattys.cloud` (mirror the existing `foundry` / `llm` records, including the `import`
   block if the record already exists).
2. **R2 bucket** — `forgejo-backups`, EU location (`WEUR` or `EEUR`; kruppe is EU),
   `cors = []` (server-only, like the sillybus Litestream bucket).
3. **R2 token** — a **bespoke `cloudflare_account_token`** scoped read+write to
   `forgejo-backups` only (reuse the `r2_bucket_item_write_pgid` / `_read_pgid` pattern
   from `credentials_cloudflare_tokens.tf`; resource string
   `com.cloudflare.edge.r2.bucket.${account_id}_default_forgejo-backups`). Do **not**
   route it through the `for_each = local.services` loop.
4. **Output** the token's `access_key_id` + `secret_access_key` (sha256-derived) so they
   can be copied into kruppe's sops secrets.

### Component 2 — nixos-config, compute on kruppe

1. **New module** `nixos/modules/home-server/forgejo.nix`, imported by
   `nixos/hosts/kruppe.nix`. Uses `services.forgejo`.
   - **DB:** SQLite (module default). Data dir `/var/lib/forgejo` (persists — kruppe has
     no impermanence).
   - `settings.server.DOMAIN = "git.mattys.cloud"`,
     `ROOT_URL = "https://git.mattys.cloud/"`, HTTP on `127.0.0.1:3000`.
   - `settings.service.DISABLE_REGISTRATION = true` — no public signup; create the admin
     account manually (`forgejo admin user create`).
   - **Built-in SSH server disabled**; git-SSH served by **system OpenSSH**, reachable
     over **Tailscale + LAN only** (see Component 3). Set `SSH_DOMAIN =
     "git.mattys.cloud"`, `SSH_PORT = 22`, `START_SSH_SERVER = false`. Exact NixOS option
     names pinned during implementation.
2. **nginx** — in `nixos/modules/home-server/reverse-proxy.nix`, add a
   `git.mattys.cloud` vhost: `forceSSL` + `enableACME`, `proxyPass` →
   `http://127.0.0.1:3000`, `proxyWebsockets = true`, and
   `client_max_body_size 512M;` (large pushes / LFS).
3. **Backup** — new `nixos/modules/home-server/forgejo-backup.nix` (or folded into the
   forgejo module):
   - systemd service + timer (e.g. daily).
   - **Pre-step:** `sqlite3 /var/lib/forgejo/data/forgejo.db ".backup /run/…/forgejo.db"`
     for a consistent DB snapshot (avoids copying a live WAL DB).
   - **restic** snapshots the repo tree (`/var/lib/forgejo/data/…`) + the DB copy →
     `s3:<account>.r2.cloudflarestorage.com/forgejo-backups`. Client-side encrypted.
   - **Retention:** `--keep-daily 7 --keep-weekly 4 --keep-monthly 6` via
     `restic forget --prune`.
   - Secrets (restic repo password + R2 `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`)
     from **sops** (`secrets/kruppe.yaml`), passed via `EnvironmentFile` /
     `LoadCredential` — never in the Nix store.
   - This is **new, reusable backup infra** — first restic setup in this repo; other
     kruppe services can adopt the same module later.

### Component 3 — SSH: hardened, Tailscale + LAN only (NOT public)

**Corrected assumption:** port 22 is open in the *OS* firewall (`services.openssh`
defaults `openFirewall = true`), but the network **edge only forwards 80/443**, so 22 is
**not currently reachable from the internet**. SSH today works over **LAN + Tailscale**.
Exposing 22 publicly would therefore be a *new* exposure — and it's unnecessary for a
personal git server.

**Decision: do NOT expose 22 publicly. git-SSH goes over Tailscale + LAN only.** A phone
or non-tailnet device clones over **public HTTPS (443)** instead. This gives zero public
SSH surface while keeping full convenience on your own machines.

Plan:

- **Delete `nixos/modules/home-server/ssh-hardening.nix`** (dead code — forces port 2222
  and `AllowUsers = ["matt"]`, both wrong here) and **harden `nixos/modules/ssh.nix`
  directly** as the single source of SSH config:
  - `PasswordAuthentication = false`, `PermitRootLogin = "no"`, strong ciphers/MACs/kex,
    `MaxAuthTries`. Stay on port 22.
  - **`services.openssh.openFirewall = false`** — do not open 22 globally.
  - Open 22 **only** on `tailscale0` (already a `trustedInterface`, so effectively
    covered) and the home LAN `192.168.0.0/24` (e.g.
    `networking.firewall.interfaces."192.168.0.0/24"...` via a LAN interface allow, or an
    explicit source-restricted rule). Exact mechanism pinned in implementation.
    Result: **22 is unreachable from the public interface by construction**, independent
    of what the router forwards.
- Allow the **forgejo** user for SSH, restricted to git: keys resolved by Forgejo
  (`AuthorizedKeysCommand`/managed `authorized_keys`), locked to a `forgejo serv`
  **forced command** — a git transaction, never a shell. Admin login (`matt`) stays
  key-only.
- Keep the fail2ban `sshd` jail.

### Component 4 — Declarative Tailscale, fleet-wide (credentials via sops, no interactive login)

**Corrected assumption:** Tailscale is enabled in config but kept *off at runtime*
(turned off via CLI), partly due to past connectivity issues — likely a non-declarative
flag (accidental exit-node or `--accept-dns` clobbering DNS). Since git-SSH now depends on
the tailnet, and per the user's request, Tailscale must come up **declaratively and
deterministically on all devices**.

**Scope:** `nixos/modules/tailscale.nix` is imported via `common.nix` by **all 5 hosts**
(karsa, kruppe, mappo, samar, tehol) — one module change covers the fleet. This is a
**prerequisite** for the Forgejo git-SSH-over-tailnet flow and is independently valuable,
so it is sequenced as **Phase 0**.

Plan:

- In `tailscale.nix`, add **`services.tailscale.authKeyFile`** → a sops secret, plus
  explicit `extraUpFlags`/`extraSetFlags`, and keep `useRoutingFeatures = "client"` but
  **do not auto-select an exit node**. Decide MagicDNS (`--accept-dns`) behavior
  explicitly (the likely cause of the past "network issues"). `tailscaled` runs
  `tailscale up` with the key at boot — **no interactive login on any host**.
- **Auth key:** one **reusable, pre-authorized, tagged** auth key from the admin console,
  shared across hosts. Store it in a **shared sops secret** (new `secrets/common.yaml` or
  similar) whose `creation_rules` grant every host's age key — rather than duplicating it
  per-host file.
- **sops prerequisite:** `.sops.yaml` currently registers age keys only for **kruppe +
  mappo**. Add age recipients for **karsa, tehol, samar** (derive each via
  `ssh-keyscan -t ed25519 <host> | ssh-to-age`) so every host can decrypt the shared
  Tailscale secret. This is the main mechanical cost of going fleet-wide.
- **Disable node-key expiry** for each host in the Tailscale admin console after first
  join — nodes then stay connected indefinitely; the auth key is only a bootstrap.
- **Auth-key expiry (≤90 days)** only affects *re-joining*; with node-key expiry disabled
  it's a non-issue in steady state. Rotate the shared key in sops on a from-scratch
  rebuild. Longer-term upgrade: a **Tailscale OAuth client** (non-expiring secret that
  mints tagged keys) instead of a static auth key.
- Per-host caveat: non-NixOS devices (phone, work laptop) aren't covered here — they use
  the Tailscale app, or clone over public HTTPS.

### Git transport

Both enabled, with different reachability:
- **HTTPS (public, 443)** — `https://git.mattys.cloud/...`, auth via Forgejo access token
  (git credential helper). Works from any device, no Tailscale required. Primary/portable.
- **SSH (Tailscale + LAN only, 22)** — `git@git.mattys.cloud:owner/repo.git` (or a
  tailnet/LAN name). Requires the client to be on the tailnet or LAN.

### Firewall

- **Public TCP: 80, 443 only** (nginx/ACME). **22 is NOT public** —
  `openssh.openFirewall = false`, 22 allowed only on `tailscale0` + `192.168.0.0/24`.
- UDP: Tailscale port (already open in `tailscale.nix`).

## Data flow

- **Push/pull:** client → 443 (HTTPS, public) or 22 (SSH, tailnet/LAN only) → Forgejo →
  repos on `/var/lib/forgejo`.
- **Backup:** timer → sqlite `.backup` → restic (encrypt) → R2 `forgejo-backups`.
- **Restore:** `restic restore` from R2 to `/var/lib/forgejo`, restore DB copy, start
  Forgejo. (Restore drill belongs in the implementation plan / runbook.)

## Secrets

| Secret | Where stored | Consumed by |
|---|---|---|
| Tailscale reusable tagged auth key | shared sops file (e.g. `secrets/common.yaml`), readable by all host age keys | `services.tailscale.authKeyFile` on every host |
| R2 access key id / secret (scoped to `forgejo-backups`) | `secrets/kruppe.yaml` (sops) | restic backup service |
| restic repository password | `secrets/kruppe.yaml` (sops) | restic backup service |
| GitHub PAT (migration, temporary) | not committed; used once, then revoked | Forgejo importer |

R2 token minting flow: infra `tofu apply` → `tofu output` the R2 token → paste into
`secrets/kruppe.yaml` with `sops`. sops requires each consuming host's age key in
`.sops.yaml` (kruppe already present; karsa/tehol/samar to be added in Phase 0).

## One-time migration (private GitHub repos)

1. Create a GitHub **PAT** with repo scope (read).
2. Forgejo → *New Migration* → GitHub; import each private repo **with** issues, PRs,
   wiki, releases, labels, milestones.
3. Verify a couple of repos (issues/PRs present, clone works over both HTTPS and SSH).
4. **Revoke/delete the PAT.**
5. Everything imported stays private on kruppe.

## Compute footprint

Forgejo idles ~40–80 MB RAM, single Go binary, disk = repo sizes. Negligible on kruppe.
(For contrast, GitLab CE would need 2–3 GB+ RAM and 4 cores — rejected as overkill.)

## Risks & mitigations

- **SSH exposure.** 22 is **not** public — allowed only on `tailscale0` + LAN, with
  key-only auth, hardened ciphers, fail2ban, forced-command git keys, no root login.
- **Tailscale becomes a hard dependency for git-SSH.** Mitigation: public HTTPS-git (443)
  works with no tailnet, so a Tailscale outage never blocks pushing. Declarative
  `authKeyFile` + explicit flags prevent the past "turn it off" failure mode.
- **Fleet-wide Tailscale change risk.** Applying to all 5 hosts at once could repeat the
  old connectivity problem. Mitigation: pin DNS/route flags explicitly; roll out/verify
  on one host before the fleet.
- **Backup never tested = no backup.** Mitigation: include a restore drill in the
  implementation plan; alert/log on backup failure.
- **SQLite live-copy corruption.** Mitigation: `sqlite3 .backup` before restic, not a
  raw file copy.
- **ACME for `git.mattys.cloud`.** Mitigation: same HTTP-01 flow as existing subdomains;
  DNS must propagate before first cert issue.
- **Single copy of encryption/restic password.** Mitigation: ensure the restic password
  itself is recoverable independently of kruppe (e.g. in the existing password manager),
  or a restore is impossible after a kruppe loss.

## Open questions for implementation plan

- Exact `services.forgejo` NixOS option names for system-sshd git integration.
- Exact firewall mechanism to scope 22 to LAN + `tailscale0` while `openFirewall = false`.
- Tailscale flag policy: MagicDNS (`--accept-dns`) on/off, `--accept-routes`, no exit node.
- Auth-key type now (static reusable) vs OAuth-client upgrade later.
- Backup cadence (daily assumed) and whether to also `git push --mirror` critical repos
  to a second remote as belt-and-suspenders.
- R2 bucket region (`WEUR` vs `EEUR`).

## Rough implementation order

**Phase 0 — Declarative Tailscale, fleet-wide (prerequisite, independently useful):**
1. Add karsa/tehol/samar age recipients to `.sops.yaml` (via `ssh-to-age`).
2. Create shared sops secret with a reusable tagged Tailscale auth key.
3. Update `tailscale.nix`: `authKeyFile` + explicit `extraUpFlags`. Roll out + verify on
   one host, then the fleet. Disable node-key expiry per host in the admin console.

**Phase 1 — Cloud resources (infra):**
4. infra: `git.mattys.cloud` DNS + `forgejo-backups` R2 bucket + scoped token; apply;
   `tofu output` creds.

**Phase 2 — Forgejo on kruppe (nixos-config):**
5. sops-add R2 + restic creds to `secrets/kruppe.yaml`.
6. `forgejo.nix` + nginx vhost; delete `ssh-hardening.nix`, harden `ssh.nix`, scope 22 to
   tailnet/LAN; deploy; create admin user.
7. `forgejo-backup.nix`; deploy; verify a backup lands in R2; **restore drill**.

**Phase 3 — Migration:**
8. Migrate private GitHub repos; verify (issues/PRs, clone over HTTPS + SSH); revoke PAT.
