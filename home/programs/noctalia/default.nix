{
  config,
  device,
  lib,
  pkgs,
  ...
}:
let
  laptops = [
    "mappo"
    "tehol"
  ];
  profile = if builtins.elem device laptops then "laptop" else "desktop";

  # Pinned so a plugin update is a deliberate hash bump; [plugins] auto_update
  # is off and the shell never fetches this itself.
  communityPlugins = pkgs.fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "community-plugins";
    rev = "0732cf41b484893691f6be172045d8b8d25009c1";
    hash = "sha256-rKT7LCVKVMW9lxBNlWeh/eaQIsQuUxLLs5e5/oU73wM=";
  };

  # Swaps the bundled colour PNG for a themed glyph. replace-fail is the point:
  # a rev bump that touches this block breaks the build rather than silently
  # restoring the green logo.
  tailscalePlugin = pkgs.runCommand "noctalia-plugin-tailscale" { } ''
    cp -r ${communityPlugins}/tailscale $out
    chmod -R u+w $out
    substituteInPlace $out/widget.luau \
      --replace-fail ${lib.escapeShellArg "    ui.image({"} ${lib.escapeShellArg "    ui.glyph({"} \
      --replace-fail ${lib.escapeShellArg "      path = running and ICON_ON or ICON_OFF,"} ${lib.escapeShellArg "      name = \"circles\","} \
      --replace-fail ${lib.escapeShellArg "      width = 16,"} ${lib.escapeShellArg "      size = 16,"} \
      --replace-fail ${lib.escapeShellArg "      fit = \"contain\","} ${lib.escapeShellArg "      color = running and \"on_surface\" or \"on_surface_variant\","}
  '';

  # Noctalia merges every *.toml directly in its config dir alphabetically, so
  # the numeric prefixes are the layering. Assembling them here lets one
  # validate call check the merge the way the running shell loads it.
  configDir = pkgs.runCommand "noctalia-config-${device}" { } ''
    install -Dm444 ${./config/base.toml} $out/00-base.toml
    install -Dm444 ${./config/profiles/${profile}.toml} $out/10-${profile}.toml
    install -Dm444 ${./config/devices/${device}.toml} $out/20-${device}.toml
    ${lib.getExe config.programs.noctalia.package} config validate $out
  '';
in
{
  programs.noctalia = {
    enable = true;
    customPalettes.Everforest = ./palettes/everforest.json;
  };

  # davemhammer/tailscale declares these as dependencies and shells out to both.
  home.packages = [ pkgs.xdg-utils ];

  xdg.configFile = {
    "noctalia/00-base.toml".source = "${configDir}/00-base.toml";
    "noctalia/10-${profile}.toml".source = "${configDir}/10-${profile}.toml";
    "noctalia/20-${device}.toml".source = "${configDir}/20-${device}.toml";

    # Referenced as an absolute path by [widget.control-center] custom_image.
    "noctalia/nixos.svg".source =
      "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
  };

  # Noctalia treats this directory as a built-in "local" plugin source; the
  # plugin still has to be listed under [plugins] enabled to activate.
  home.file.".local/share/noctalia/plugins/latency-monitor" = {
    source = ./plugins/latency-monitor;
    recursive = true;
  };

  home.file.".local/share/noctalia/plugins/taildrop" = {
    source = ./plugins/taildrop;
    recursive = true;
  };

  home.file.".local/share/noctalia/plugins/tailscale" = {
    source = tailscalePlugin;
    recursive = true;
  };
}
