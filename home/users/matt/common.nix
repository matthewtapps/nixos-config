{ config, pkgs, ... }:
{
  programs.home-manager.enable = true;

  home.activation.report-changes = config.lib.dag.entryAnywhere ''
    ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff $oldGenPath $newGenPath
  '';

  home.username = "matt";
  home.homeDirectory = "/home/matt";

  home.sessionVariables = {
    EDITOR = "nvim";
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

    lsof
    clipman
    wl-clipboard
    xdg-desktop-portal-hyprland
    iproute2
    lm_sensors
  ];

  xdg.userDirs = {
    createDirectories = true;
    documents = "${config.home.homeDirectory}/documents";
    download = "${config.home.homeDirectory}/downloads";
    music = "${config.home.homeDirectory}/music";
    pictures = "${config.home.homeDirectory}/pictures";
    videos = "${config.home.homeDirectory}/videos";
    templates = "${config.home.homeDirectory}/templates";
    extraConfig = {
      XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/screenshots";
    };
  };

  imports = [
    #    ./theme.nix
    ../../programs/zsh/default.nix
    ../../programs/neovim/default.nix
    ../../programs/git.nix
    ../../programs/direnv.nix
    #   ../../programs/vscode.nix
  ];

}
