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

  programs.ssh.settings."gitlab" = {
    HostName = "gitlab.countersight.co";
    Port = 2200;
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
