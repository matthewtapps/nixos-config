{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    thunderbird
    aerc
    teams-for-linux
    github-copilot-cli
    dbgate
  ];

  xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
    disableGpu = false;
    wayland = {
      xwaylandOptimizations = true;
    };
  };
}
