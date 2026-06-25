# Dual Claude harness + ahvi telemetry — design

Date: 2026-06-25

## Goal

Run two Claude Code harnesses on the laptop from one binary, segregated by
config dir, each streaming full OpenTelemetry (logs, traces, prompts, tool
content) to a separate ahvi instance on samar (`192.168.0.170`). Profiles let
personal and work usage be kept apart.

## Profile mapping

| Command   | Profile  | Config dir       | ahvi endpoint              |
| --------- | -------- | ---------------- | -------------------------- |
| `claude`  | personal | `~/.claude`      | `http://192.168.0.170:8421` |
| `cclaude` | work     | `~/.claude-alt`  | `http://192.168.0.170:8431` |

(Mapping is a convention; swap endpoints to flip.)

## Components

### 1. Laptop — `home/programs/claude-code.nix` (refactor)

Current module materialises one config dir (`~/.claude`): wrapped `claude`
binary, `settings.json`, `claude-powerline.json`, and the pinned plugin tree.
Refactor so the per-profile bits are produced by a function and the two profiles
share all plugin/marketplace logic.

- **`mkProfile { dir, endpoint }`** produces the `settings.json` content (with a
  per-profile `env` block + statusline command) for one config dir.
- **`claude`**: unchanged wrapped binary; uses the default `~/.claude`.
- **`cclaude`**: a `pkgs.writeShellScriptBin "cclaude"` wrapper:
  ```sh
  export CLAUDE_CONFIG_DIR="$HOME/.claude-alt"
  exec ${claude-code}/bin/claude "$@"
  ```
  Inherits the wrapped binary's `node`-on-PATH. Added to `home.packages`.
- **Shared plugins, no duplication**: the activation script materialises the
  plugin / cache / marketplace tree once under `~/.claude/plugins` (as today).
  `~/.claude-alt/plugins` is a symlink to `~/.claude/plugins`. `installPath`
  values in `installed_plugins.json` are absolute, so the shared state files
  resolve for both profiles. `~/.claude-alt` gets its own `settings.json` and
  `claude-powerline.json`.

### 2. Telemetry `env` block (per profile, in `settings.json`)

Level: full prompts and tool content, no raw API bodies.

```
CLAUDE_CODE_ENABLE_TELEMETRY      = "1"
CLAUDE_CODE_ENHANCED_TELEMETRY_BETA = "1"      # gate required for traces
OTEL_LOGS_EXPORTER                = "otlp"
OTEL_TRACES_EXPORTER              = "otlp"
OTEL_METRICS_EXPORTER             = "none"     # ahvi has no /v1/metrics route
OTEL_EXPORTER_OTLP_PROTOCOL       = "http/json" # ahvi parses JSON, not protobuf
OTEL_EXPORTER_OTLP_ENDPOINT       = "http://192.168.0.170:<8421|8431>"
OTEL_LOG_TOOL_DETAILS             = "1"         # tool inputs
OTEL_LOG_TOOL_CONTENT             = "1"         # tool results
OTEL_LOG_USER_PROMPTS             = "1"         # full prompt text
OTEL_LOG_RAW_API_BODIES           = "0"         # skip giant duplicate bodies
OTEL_LOGS_EXPORT_INTERVAL         = "2000"      # prompt visibility mid-session
```

### 3. Quota statusline tee (per profile)

Quota (`rate_limits`) and live context usage reach only the statusline hook,
never the OTLP wire. `settings.json` allows one `statusLine.command`. So replace
the command with a per-profile wrapper script that:

1. reads the hook JSON payload on stdin,
2. POSTs it to `<endpoint>/v1/logs` as an `ahvi.quota_sample` OTLP log,
   best-effort and bounded (`curl -m 1 … || true` — never stalls or breaks the
   statusline if ahvi is down),
3. execs the real `claude-powerline --config <dir>/claude-powerline.json` with
   the same payload on stdin.

Inlined in Nix (`pkgs.writeShellScript`); the endpoint is baked per profile. No
dependency on the ahvi flake. Requires `jq` + `curl` in the wrapper's
`runtimeInputs` / PATH.

### 4. samar — `nixos/hosts/samar.nix` (firewall only)

No systemd service (chosen: firewall + env, run manually). Open ingest + UI
ports:

```nix
networking.firewall.allowedTCPPorts = [ 9192 8420 8421 8430 8431 ];
```

Run two ahvi instances manually, each bound to `0.0.0.0` (default `127.0.0.1`
refuses LAN traffic) with distinct ingest/UI ports and DuckDB files:

```sh
# personal
AHVI_OTLP_ADDR=0.0.0.0:8421 AHVI_API_ADDR=0.0.0.0:8420 \
  AHVI_DB=<path>/personal.duckdb ahvi-server
# work
AHVI_OTLP_ADDR=0.0.0.0:8431 AHVI_API_ADDR=0.0.0.0:8430 \
  AHVI_DB=<path>/work.duckdb ahvi-server
```

ahvi-server env reference: `AHVI_OTLP_ADDR` (ingest, dflt `127.0.0.1:8421`),
`AHVI_API_ADDR` (UI/query, dflt `127.0.0.1:8420`), `AHVI_DB`,
`AHVI_CAPTURE_RAW_BODIES`, `AHVI_STATIC_DIR`.

## Data flow

```
claude  (~/.claude)     ─OTLP/http-json─▶ samar:8421 ─▶ ahvi personal ─▶ UI :8420
        statusline tee  ─/v1/logs──────▶ samar:8421
cclaude (~/.claude-alt) ─OTLP/http-json─▶ samar:8431 ─▶ ahvi work     ─▶ UI :8430
        statusline tee  ─/v1/logs──────▶ samar:8431
```

## Error handling

- Statusline tee is best-effort and bounded; ahvi being down never affects the
  statusline render.
- OTLP export is fire-and-forget by Claude Code; an unreachable endpoint drops
  telemetry but does not block the session.

## Out of scope / deferred

- NixOS systemd service for ahvi-server on samar (reboot-safety). Easy follow-up.
- Reverse proxy / TLS for the ahvi ports (LAN-only for now).
- Second ahvi instance provisioning is manual (two `ahvi-server` processes).

## Verification

- `nix flake check` / build the home-manager + samar configs.
- After switch: `cclaude` exists on PATH and launches with
  `CLAUDE_CONFIG_DIR=~/.claude-alt`; `~/.claude-alt/settings.json` carries the
  `8431` endpoint, `~/.claude/settings.json` the `8421` endpoint.
- `~/.claude-alt/plugins` is a symlink to `~/.claude/plugins`.
- With ahvi running on samar (bound to `0.0.0.0`), a session in each harness
  shows token/prompt/tool data in the matching ahvi UI; statusline quota samples
  arrive.
```
