# Dual Claude Harness + ahvi Telemetry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run two Claude Code harnesses (`claude` personal, `cclaude` work) from one binary, segregated by `CLAUDE_CONFIG_DIR`, each streaming full OpenTelemetry to a separate ahvi instance on samar (`192.168.0.170`).

**Architecture:** Refactor `home/programs/claude-code.nix` so per-profile config (settings.json + telemetry env + statusline tee) is produced by a `mkSettings` function, sharing the pinned plugin tree. `claude` uses `~/.claude` → `:8421`; a `cclaude` wrapper sets `CLAUDE_CONFIG_DIR=~/.claude-alt` → `:8431`. `~/.claude-alt/plugins` symlinks the shared tree. samar opens the ingest/UI firewall ports.

**Tech Stack:** Nix / home-manager, NixOS firewall, Claude Code OTel env vars, ahvi OTLP/HTTP-JSON.

**Note on TDD:** This is declarative Nix config — there is no unit-test harness. The TDD cycle here is **edit → `nixos-rebuild build` (eval) → inspect generated artifact → commit**. Each task ends with a build that must succeed and an inspection of the produced file.

**Build/verify commands:**
- Laptop (home-manager via host `tehol`): `nixos-rebuild build --flake .#tehol`
- Server: `nixos-rebuild build --flake .#samar`
- Inspect generated home files in the build result under `result/` is not exposed for home-manager; instead inspect after a real switch, or eval directly (shown per task).

---

## File Structure

- `home/programs/claude-code.nix` — **modify**. Add telemetry `env`, statusline tee, `mkSettings` function, `cclaude` wrapper, and `~/.claude-alt` materialisation. Single file owns all Claude Code laptop config.
- `nixos/hosts/samar.nix` — **modify** one line. Open ahvi ingest/UI firewall ports.
- `docs/superpowers/specs/2026-06-25-dual-claude-harness-ahvi-telemetry-design.md` — reference spec (already committed).

---

## Task 1: samar firewall ports

**Files:**
- Modify: `nixos/hosts/samar.nix:35`

- [ ] **Step 1: Open ahvi ingest + UI ports**

Replace line 35:

```nix
  networking.firewall.allowedTCPPorts = [ 9192 ];
```

with:

```nix
  # 9192 existing; 8420/8421 personal ahvi (UI/ingest), 8430/8431 work ahvi.
  networking.firewall.allowedTCPPorts = [
    9192
    8420
    8421
    8430
    8431
  ];
```

- [ ] **Step 2: Build samar to verify eval**

Run: `nixos-rebuild build --flake .#samar`
Expected: builds with no error.

- [ ] **Step 3: Confirm ports in the built firewall config**

Run: `nix eval --raw .#nixosConfigurations.samar.config.networking.firewall.allowedTCPPorts --apply 'builtins.toJSON'`
Expected output contains: `[9192,8420,8421,8430,8431]`

- [ ] **Step 4: Commit**

```bash
git add nixos/hosts/samar.nix
git commit -m "samar: open ahvi OTLP ingest + UI firewall ports"
```

---

## Task 2: Telemetry env block + statusline tee helpers

Add two helper functions to the `let` block of `home/programs/claude-code.nix`. No behaviour change yet — these are consumed in Task 3.

**Files:**
- Modify: `home/programs/claude-code.nix` (let block, after the `claude-powerline` binding near line 29)

- [ ] **Step 1: Add `mkEnv` and `mkStatusline` to the `let` block**

Insert after the `home`/`pluginsDir` bindings (around line 32), before the `mp = { … }` block:

```nix
  # Full-telemetry OTel env for ahvi: logs + traces + prompts + tool content,
  # no raw API bodies. http/json because ahvi parses JSON not protobuf; metrics
  # off because ahvi has no /v1/metrics route. Endpoint is per-profile.
  mkEnv = endpoint: {
    CLAUDE_CODE_ENABLE_TELEMETRY = "1";
    CLAUDE_CODE_ENHANCED_TELEMETRY_BETA = "1";
    OTEL_LOGS_EXPORTER = "otlp";
    OTEL_TRACES_EXPORTER = "otlp";
    OTEL_METRICS_EXPORTER = "none";
    OTEL_EXPORTER_OTLP_PROTOCOL = "http/json";
    OTEL_EXPORTER_OTLP_ENDPOINT = endpoint;
    OTEL_LOG_TOOL_DETAILS = "1";
    OTEL_LOG_TOOL_CONTENT = "1";
    OTEL_LOG_USER_PROMPTS = "1";
    OTEL_LOG_RAW_API_BODIES = "0";
    OTEL_LOGS_EXPORT_INTERVAL = "2000";
  };

  # Statusline wrapper: tee the hook payload to ahvi as an ahvi.quota_sample OTel
  # log (best-effort, bounded — never stalls or breaks the statusline), then run
  # the real claude-powerline with the config in this profile's dir.
  mkStatusline =
    { endpoint, dir }:
    pkgs.writeShellScript "ahvi-statusline" ''
      input="$(cat)"
      ts="$(${pkgs.coreutils}/bin/date +%s%N)"
      ${pkgs.jq}/bin/jq -cn --arg hd "$input" --arg ts "$ts" \
        '{resourceLogs:[{scopeLogs:[{logRecords:[{timeUnixNano:$ts,body:{stringValue:"ahvi.quota_sample"},attributes:[{key:"ahvi.hookdata",value:{stringValue:$hd}}]}]}]}]}' \
        | ${pkgs.curl}/bin/curl -s -m 1 -XPOST "${endpoint}/v1/logs" -H 'content-type: application/json' --data-binary @- >/dev/null 2>&1 || true
      exec ${claude-powerline}/bin/claude-powerline --config ${dir}/claude-powerline.json <<<"$input"
    '';
```

- [ ] **Step 2: Build to verify eval (helpers unused yet — confirm no syntax error)**

Run: `nixos-rebuild build --flake .#tehol`
Expected: builds with no error (unused `let` bindings are fine in Nix).

- [ ] **Step 3: Commit**

```bash
git add home/programs/claude-code.nix
git commit -m "claude-code: add ahvi telemetry env + statusline tee helpers"
```

---

## Task 3: Convert `settings` to per-profile `mkSettings`

Replace the static `settings` attrset with a function so each profile gets its own endpoint, env, and statusline. The personal profile keeps the existing `~/.claude` behaviour plus telemetry.

**Files:**
- Modify: `home/programs/claude-code.nix` (the `settings = { … }` block, ~lines 129-152, and the `settingsJson` binding ~line 154)

- [ ] **Step 1: Replace `settings` with `mkSettings`**

Replace:

```nix
  settings = {
    model = "opus";
    tui = "fullscreen";
    permissions = {
      defaultMode = "auto";
    };
    statusLine = {
      type = "command";
      command = "claude-powerline --config ~/.claude/claude-powerline.json";
    };
    enabledPlugins = builtins.listToAttrs (
      map (p: {
        name = "${p.plugin}@${p.mp}";
        value = true;
      }) pluginCaches
    );
    extraKnownMarketplaces = lib.mapAttrs (_: repo: {
      source = {
        source = "github";
        inherit repo;
      };
    }) marketplaceRepos;
    skipAutoPermissionPrompt = true;
  };
```

with:

```nix
  mkSettings =
    { endpoint, dir }:
    {
      model = "opus";
      tui = "fullscreen";
      permissions = {
        defaultMode = "auto";
      };
      env = mkEnv endpoint;
      statusLine = {
        type = "command";
        command = "${mkStatusline { inherit endpoint dir; }}";
      };
      enabledPlugins = builtins.listToAttrs (
        map (p: {
          name = "${p.plugin}@${p.mp}";
          value = true;
        }) pluginCaches
      );
      extraKnownMarketplaces = lib.mapAttrs (_: repo: {
        source = {
          source = "github";
          inherit repo;
        };
      }) marketplaceRepos;
      skipAutoPermissionPrompt = true;
    };

  # Personal profile (default ~/.claude) -> ahvi :8421.
  personalDir = "${home}/.claude";
  # Work profile (~/.claude-alt, via cclaude wrapper) -> ahvi :8431.
  altDir = "${home}/.claude-alt";

  settingsPersonalJson = pkgs.writeText "claude-settings.json" (
    builtins.toJSON (mkSettings {
      endpoint = "http://192.168.0.170:8421";
      dir = personalDir;
    })
  );
  settingsAltJson = pkgs.writeText "claude-settings-alt.json" (
    builtins.toJSON (mkSettings {
      endpoint = "http://192.168.0.170:8431";
      dir = altDir;
    })
  );
```

- [ ] **Step 2: Replace the old `settingsJson` binding**

Delete the now-stale line (~154):

```nix
  settingsJson = pkgs.writeText "claude-settings.json" (builtins.toJSON settings);
```

(It is replaced by `settingsPersonalJson` / `settingsAltJson` above. Leave `installedPluginsJson` and `knownMarketplacesJson` untouched.)

- [ ] **Step 3: Point the personal install at the renamed var**

In the activation script, change the settings install line (~line 200):

```nix
    $DRY_RUN_CMD ${install} -m644 ${settingsJson} "$root/settings.json"
```

to:

```nix
    $DRY_RUN_CMD ${install} -m644 ${settingsPersonalJson} "$root/settings.json"
```

- [ ] **Step 4: Build to verify eval**

Run: `nixos-rebuild build --flake .#tehol`
Expected: builds with no error. (Fails loudly if any `settingsJson` reference remains — grep to be sure: `grep -n 'settingsJson' home/programs/claude-code.nix` returns nothing.)

- [ ] **Step 5: Commit**

```bash
git add home/programs/claude-code.nix
git commit -m "claude-code: parameterise settings per profile with telemetry env"
```

---

## Task 4: `cclaude` wrapper + `~/.claude-alt` materialisation

Add the second binary and materialise the alt config dir: its own settings.json + claude-powerline.json, with `plugins` symlinked to the shared tree.

**Files:**
- Modify: `home/programs/claude-code.nix` (the `let` block for the wrapper ~line 28-29; `home.packages` ~line 174-177; the activation script tail ~line 195-201)

- [ ] **Step 1: Define the `cclaude` wrapper in the `let` block**

After the `claude-powerline` binding (~line 29), add:

```nix
  cclaude = pkgs.writeShellScriptBin "cclaude" ''
    export CLAUDE_CONFIG_DIR="${home}/.claude-alt"
    exec ${claude-code}/bin/claude "$@"
  '';
```

- [ ] **Step 2: Add `cclaude` to `home.packages`**

Change:

```nix
  home.packages = [
    claude-code
    claude-powerline
  ];
```

to:

```nix
  home.packages = [
    claude-code
    claude-powerline
    cclaude
  ];
```

- [ ] **Step 3: Materialise `~/.claude-alt` in the activation script**

After the existing personal-dir installs (after the `claude-powerline.json` install line ~201, still inside `home.activation.claudeCode`), append:

```nix

    # Work profile dir: own settings + powerline, plugins symlinked to the
    # shared tree (installPaths in installed_plugins.json are absolute).
    alt="${home}/.claude-alt"
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$alt"
    $DRY_RUN_CMD ln -sfn "$root/plugins" "$alt/plugins"
    $DRY_RUN_CMD ${install} -m644 ${settingsAltJson} "$alt/settings.json"
    $DRY_RUN_CMD ${install} -m644 ${./claude-powerline.json} "$alt/claude-powerline.json"
```

- [ ] **Step 4: Build to verify eval**

Run: `nixos-rebuild build --flake .#tehol`
Expected: builds with no error.

- [ ] **Step 5: Commit**

```bash
git add home/programs/claude-code.nix
git commit -m "claude-code: add cclaude work profile (~/.claude-alt, ahvi :8431)"
```

---

## Task 5: Switch and verify end-to-end

**Files:** none (verification only).

- [ ] **Step 1: Switch the laptop config**

Run: `nixos-rebuild switch --flake .#tehol` (use the user's normal switch command, e.g. `sudo nixos-rebuild switch` or a deploy alias).
Expected: activation runs `claudeCode` with no error.

- [ ] **Step 2: Verify both binaries and config dirs**

Run:
```bash
which claude cclaude
test -L ~/.claude-alt/plugins && echo "alt plugins symlinked OK"
readlink ~/.claude-alt/plugins
```
Expected: both binaries resolve; `~/.claude-alt/plugins` is a symlink to `~/.claude/plugins`.

- [ ] **Step 3: Verify per-profile endpoints in settings.json**

Run:
```bash
grep OTEL_EXPORTER_OTLP_ENDPOINT ~/.claude/settings.json
grep OTEL_EXPORTER_OTLP_ENDPOINT ~/.claude-alt/settings.json
```
Expected: personal → `http://192.168.0.170:8421`; alt → `http://192.168.0.170:8431`. Both also contain `OTEL_LOG_USER_PROMPTS":"1"` and `OTEL_LOG_RAW_API_BODIES":"0"`.

- [ ] **Step 4: Confirm `cclaude` targets the alt dir**

Run: `cclaude --help >/dev/null 2>&1; cat $(which cclaude)`
Expected: wrapper exports `CLAUDE_CONFIG_DIR=$HOME/.claude-alt` and execs claude.

- [ ] **Step 5: Switch samar and start the two ahvi instances (manual, per design)**

Switch samar (deploy as usual), then on samar:
```bash
# personal
AHVI_OTLP_ADDR=0.0.0.0:8421 AHVI_API_ADDR=0.0.0.0:8420 AHVI_DB=~/ahvi/personal.duckdb ahvi-server &
# work
AHVI_OTLP_ADDR=0.0.0.0:8431 AHVI_API_ADDR=0.0.0.0:8430 AHVI_DB=~/ahvi/work.duckdb ahvi-server &
```
Expected: each prints `OTLP ingest on 0.0.0.0:84x1; query API on 0.0.0.0:84x0`.

- [ ] **Step 6: End-to-end smoke test**

From the laptop, run a short `claude` session and a short `cclaude` session. Open `http://192.168.0.170:8420` (personal) and `http://192.168.0.170:8430` (work).
Expected: each UI shows that session's tokens/prompts/tool activity, in the matching instance only; statusline quota samples appear.

- [ ] **Step 7: Final branch wrap-up**

No code change. Confirm `git status` clean and the branch holds Tasks 1-4 commits.

---

## Self-Review

**Spec coverage:**
- Profile mapping (claude/cclaude, dirs, endpoints) → Tasks 3, 4, 5. ✓
- mkProfile/mkSettings refactor → Task 3. ✓
- Shared plugins via symlink → Task 4 Step 3, verified Task 5 Step 2. ✓
- Full-prompt telemetry env block → Task 2 (`mkEnv`), applied Task 3, verified Task 5 Step 3. ✓
- Quota statusline tee → Task 2 (`mkStatusline`), applied Task 3. ✓
- samar firewall ports → Task 1. ✓
- Manual two-instance ahvi run / 0.0.0.0 bind → Task 5 Step 5. ✓
- Deferred items (systemd service, TLS) → correctly absent from tasks. ✓

**Placeholder scan:** No TBD/TODO; all code blocks complete; `~/ahvi/*.duckdb` paths are concrete examples the user can relocate. ✓

**Type/name consistency:** `mkEnv`, `mkStatusline`, `mkSettings`, `settingsPersonalJson`, `settingsAltJson`, `personalDir`, `altDir`, `cclaude` used consistently across Tasks 2-5. Old `settings`/`settingsJson` fully removed in Task 3 (grep-checked in Step 4). ✓
