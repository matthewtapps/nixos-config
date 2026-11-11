# Standalone ahvi-aware `claude` launchers: the single source of the ahvi MCP
# endpoint shape and the wrapper that loads it via `--mcp-config`.
#
# Imported by home/programs/claude-code.nix (the installed `claude` / `cclaude`).
#
# Claude Code does not read `mcpServers` from settings.json; MCP servers are
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

  mkWrapper =
    {
      name ? "claude",
      apiUrl,
      configSubdir ? null,
    }:
    pkgs.writeShellScriptBin name ''
      ${lib.optionalString (configSubdir != null) ''export CLAUDE_CONFIG_DIR="$HOME/${configSubdir}"''}
      exec ${claude-code}/bin/claude --mcp-config=${mkMcpJson apiUrl} "$@"
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
