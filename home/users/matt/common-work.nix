{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../../programs/gitlab/default.nix
  ];

  programs.mrRebase = {
    enable = true;
    host = "gitlab.countersight.co";
  };

  home.packages = with pkgs; [
    thunderbird
    aerc
    teams-for-linux
    github-copilot-cli
    dbgate
    inputs.todone.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
    disableGpu = false;
    wayland = {
      xwaylandOptimizations = true;
    };
    notificationMethod = "electron";
  };
}
