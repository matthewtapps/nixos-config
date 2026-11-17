{ pkgs, ... }:
{
  imports = [
    ./common.nix
    ./common-work.nix
    ../../programs/recording.nix
  ];

  home.packages = [
    (pkgs.writeShellScriptBin "tailnet-switch" ''
      choice=$(tailscale switch --list | tail -n +2 | noctalia dmenu -p Tailnet) || exit 0
      [ -n "$choice" ] && tailscale switch "''${choice%% *}"
    '')
  ];
}
