{ pkgs, inputs, ... }:
let
  # Create a wrapped version of nodejs that's only for Claude Desktop MCP servers
  claudeNodejs = pkgs.nodejs;

  # Create the MCP server config
  mcpConfig = {
    mcpServers = {
      memory = {
        command = "${claudeNodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-memory"
        ];
      };
      shadcn = {
        command = "npx";
        args = [
          "shadcn@latest"
          "mcp"
        ];
      };
    };
  };

  claude-desktop-wrapped = pkgs.writeShellScriptBin "claude-desktop" ''
    exec ${inputs.claude-desktop.packages.${pkgs.system}.claude-desktop-with-fhs}/bin/claude-desktop \
      --enable-features=UseOzonePlatform \
      --ozone-platform=wayland \
      --disable-background-mode \
      "$@"
  '';
in
{
  # Install Claude Desktop
  home.packages = [
    claude-desktop-wrapped
  ];

  # Configure Claude Desktop with MCP servers
  home.file.".config/Claude/claude_desktop_config.json" = {
    text = builtins.toJSON mcpConfig;
  };
}
