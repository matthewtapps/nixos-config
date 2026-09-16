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

  # Anything routed over the work VPN takes the nixos-hosts catalogue identity.
  programs.ssh.settings.wireguard = {
    header = "Match exec \"ip route get %h 2>/dev/null | grep -q ' dev wg0 '\"";
    User = "matthewt";
    IdentityFile = "~/.ssh/wtk-box";
    IdentitiesOnly = true;
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
