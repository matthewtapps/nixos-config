{ pkgs, ... }: {
  imports = [
    ./common.nix
    ./theme.nix
    ../../programs/ags/default.nix
    ../../programs/kitty/default.nix
    ../../programs/hypr/default.nix
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
    steam
    calibre
    qbittorrent
    zoom-us
  ];

  home.file = { ".hushlogin".text = ""; };
  services.ssh-agent.enable = true;

  programs.ssh = { enable = true; };
}
