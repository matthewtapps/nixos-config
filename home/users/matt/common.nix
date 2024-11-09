{ config, pkgs, ... }: {
  programs.home-manager.enable = true;

  home.activation.report-changes = config.lib.dag.entryAnywhere ''
    ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff $oldGenPath $newGenPath
  '';

  home.username = "matt";
  home.homeDirectory = "/home/matt";

  home.sessionVariables = {
    EDITOR = "nvim";
    HYPRSHOT_DIR = "~/screenshots/";
  };

  home.packages = with pkgs; [
    zip
    xz
    unzip
    p7zip

    iperf3
    dnsutils
    nmap

    nixpkgs-fmt

    rofi-wayland
    swww
    brightnessctl
    dart-sass
    matugen
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

    lsof
    clipman
    wl-clipboard
    xdg-desktop-portal-hyprland
    iproute2
    lm_sensors

  ];

  imports = [
    ./theme.nix
    ../../programs/zsh/default.nix
    ../../programs/neovim/default.nix
    ../../programs/git.nix
    ../../programs/direnv.nix
#   ../../programs/vscode.nix
  ];

}
