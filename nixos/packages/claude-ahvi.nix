# Standalone ahvi-aware `claude` launchers — the single source of the ahvi MCP
# endpoint shape and the wrapper that loads it via `--mcp-config`.
#
# Imported by BOTH:
#   - home/programs/claude-code.nix   (the installed `claude` / `cclaude`)
#   - flake.nix `packages` output     (so the ~/cs work devshell can hand the
#                                      same ahvi-wrapped binary to slop-cop's
#                                      mkClaudeWrapper — see that flake)
#
# Claude Code does NOT read `mcpServers` from settings.json; MCP servers are
# loaded from ~/.claude.json (volatile) or files passed via `--mcp-config`. We
# use the latter so the ahvi registration is declarative and non-volatile.
{ pkgs }:
let
  lib = pkgs.lib;
  claude-code = pkgs.callPackage ./claude-code.nix { };

  # ahvi exposes two ports per instance: OTLP/HTTP ingest (telemetry in) and a
  # query-API port (should_sample veto + the MCP feedback server).
  #   work server:     otlp 8421, api 8420
  #   personal server: otlp 8431, api 8430
  mkEndpoints =
    ahviHost:
    let
      mk =
        { otlpPort, apiPort }:
        {
          otlp = "http://${ahviHost}:${toString otlpPort}";
          api = "http://${ahviHost}:${toString apiPort}";
        };
    in
    {
      work = mk {
        otlpPort = 8421;
        apiPort = 8420;
      };
      personal = mk {
        otlpPort = 8431;
        apiPort = 8430;
      };
    };

  mkMcpJson =
    apiUrl:
    pkgs.writeText "ahvi-mcp.json" (
      builtins.toJSON {
        mcpServers.ahvi = {
          type = "http";
          url = "${apiUrl}/mcp";
        };
      }
    );

  # Wrap the real binary to load the ahvi feedback MCP server. `--mcp-config` is
  # additive to any user-scope servers, so it won't clobber `claude mcp add`
  # entries. `configSubdir` (relative to $HOME) selects an alternate config dir
  # at runtime — used by the personal `cclaude` harness (~/.claude-alt).
  mkWrapper =
    {
      name ? "claude",
      apiUrl,
      configSubdir ? null,
    }:
    pkgs.writeShellScriptBin name ''
      ${lib.optionalString (configSubdir != null) ''export CLAUDE_CONFIG_DIR="$HOME/${configSubdir}"''}
      exec ${claude-code}/bin/claude --mcp-config ${mkMcpJson apiUrl} "$@"
    '';
in
{
  inherit
    claude-code
    mkEndpoints
    mkMcpJson
    mkWrapper
    ;
}
