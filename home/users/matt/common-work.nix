{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  home.packages = with pkgs; [
    thunderbird
    aerc
    teams-for-linux
    github-copilot-cli
    dbgate
    inputs.standup.packages.${pkgs.system}.default
  ];

  xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
    disableGpu = false;
    wayland = {
      xwaylandOptimizations = true;
    };
  };
}
