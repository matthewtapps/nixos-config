{
  pkgs,
  inputs,
  ...
}:
let
  claudeNodejs = pkgs.nodejs;
  mcp-language-server = pkgs.buildGoModule {
    pname = "mcp-language-server";
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "isaacphi";
      repo = "mcp-language-server";
      rev = "main";
      sha256 = "sha256-INyzT/8UyJfg1PW5+PqZkIy/MZrDYykql0rD2Sl97Gg=";
    };
    vendorHash = "sha256-WcYKtM8r9xALx68VvgRabMPq8XnubhTj6NAdtmaPa+g=";
    subPackages = [ "." ];
    doCheck = false;
  };

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
      code-context-provider-mcp = {
        command = "npx";
        args = [
          "-y"
          "code-context-provider-mcp@latest"
        ];
      };
    };
  };

  claude-desktop-wrapped = pkgs.writeShellScriptBin "claude-desktop" ''
    EMPTY_WORKSPACE="$HOME/.cache/claude-empty-workspace"
    WORKSPACE_LINK="$HOME/.config/claude/current-workspace"

    mkdir -p "$HOME/.config/claude"

    # Use current directory if in a project, otherwise empty
    if [ "$PWD" != "$HOME" ] && [ "$PWD" != "/" ]; then
      ln -sfn "$PWD" "$WORKSPACE_LINK"
      echo "✓ Workspace: $PWD"
    else
      rm -rf "$EMPTY_WORKSPACE"
      mkdir -p "$EMPTY_WORKSPACE"
      ln -sfn "$EMPTY_WORKSPACE" "$WORKSPACE_LINK"
      echo "✓ Using empty workspace"
    fi

    nohup ${inputs.claude-desktop.packages.${pkgs.system}.claude-desktop-with-fhs}/bin/claude-desktop \
      --enable-features=UseOzonePlatform \
      --ozone-platform=wayland \
      "$@" > /dev/null 2>&1 &

    disown
    echo "Claude Desktop started (PID: $!)"
  '';
in
{
  home.packages = [
    claude-desktop-wrapped
    mcp-language-server
  ];
  home.file.".config/Claude/claude_desktop_config.json" = {
    text = builtins.toJSON mcpConfig;
  };
  home.file.".local/share/applications/claude-desktop.desktop".text = ''
    [Desktop Entry]
    Name=Claude Desktop
    Exec=${claude-desktop-wrapped}/bin/claude-desktop
    Icon=claude
    Type=Application
    Categories=Development;Utility;
  '';
}
