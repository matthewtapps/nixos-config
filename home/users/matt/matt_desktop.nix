{ pkgs, inputs, ... }:
{
  imports = [
    ./common.nix
    ./theme.nix
    ../../programs/ags/default.nix
    ../../programs/hypr/default.nix
    ../../programs/lan-mouse.nix
    ../../programs/rofi/default.nix
    ../../programs/wezterm.nix
  ];

  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    libreoffice
    firefox
    google-chrome
    spotify
    slack
    btop
    neofetch
    obsidian
    discord
    jetbrains.datagrip
    vscode
    signal-desktop
    spotify-player
    xfce.thunar
    networkmanagerapplet
    calibre
    qbittorrent
    zoom-us

    rofi-wayland
    swww
    brightnessctl
    dart-sass
    inputs.matugen.packages.${system}.default
    fd
    dconf
    hyprlock
    hyprpaper
    hyprshot
    playerctl
    pavucontrol
    overskride
    gtk-engine-murrine
    gnome-themes-extra
    inputs.zen-browser.packages.${system}.default
  ];

  home.file = {
    ".hushlogin".text = "";
  };
  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;
  };
}
