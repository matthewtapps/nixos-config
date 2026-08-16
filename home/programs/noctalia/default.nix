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
  # Noctalia is the notification daemon and the lock screen.
  services.swaync.enable = false;
  programs.hyprlock.enable = lib.mkForce false;

  programs.noctalia = {
    enable = true;
    customPalettes.Everforest = ./palettes/everforest.json;
  };

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
}
