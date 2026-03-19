{ pkgs, ... }:
{
  home.packages = with pkgs; [
    quickshell
    networkmanagerapplet
    pavucontrol
    blueman
    brightnessctl
    jq
    nerd-fonts.geist-mono
  ];

  # Disable swaync — quickshell handles notifications natively
  services.swaync.enable = false;

  xdg.configFile."quickshell".source = ./config;
}
