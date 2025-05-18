{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.home-manager.enable = true;

  home.stateVersion = "24.05";

  home.activation.report-changes = config.lib.dag.entryAnywhere ''
    ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff $oldGenPath $newGenPath
  '';

  home.username = "matt";
  home.homeDirectory = "/home/matt";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.file = {
    ".hushlogin".text = "";
  };

  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;
  };

  home.packages = with pkgs; [
    zip
    xz
    unzip
    p7zip

    iperf3
    dnsutils
    nmap
    networkmanagerapplet

    nixpkgs-fmt

    lsof
    clipman
    wl-clipboard
    xdg-desktop-portal-hyprland
    iproute2
    lm_sensors
    gimp
    zathura

    # Gurps
    gcs

    libreoffice
    spotify
    slack
    btop
    neofetch
    obsidian
    discord
    vscode
    signal-desktop-bin
    spotify-player
    xfce.thunar
    calibre
    qbittorrent
    inputs.zen-browser.packages.${system}.default
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

    jetbrains.datagrip
  ];

  xdg = {
    userDirs = {
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
    mime.enable = true;
    mimeApps = {
      enable = true;
      associations.added = {
        "inode/directory" = "thunar.desktop";
        "application/pdf" = "org.pwmt.zathura-cb.desktop";
        "x-scheme-handler/http" = "zen-beta.desktop";
        "x-scheme-handler/https" = "zen-beta.desktop";
        "x-scheme-handler/chrome" = "zen-beta.desktop";
        "text/html" = "zen-beta.desktop";
        "application/x-extension-htm" = "zen-beta.desktop";
        "application/x-extension-html" = "zen-beta.desktop";
        "application/x-extension-shtml" = "zen-beta.desktop";
        "application/xhtml+xml" = "zen-beta.desktop";
        "application/x-extension-xhtml" = "zen-beta.desktop";
        "application/x-extension-xht" = "zen-beta.desktop";
      };
      defaultApplications = {
        "inode/directory" = "thunar.desktop";
        "application/pdf" = "org.pwmt.zathura-cb.desktop";
        "x-scheme-handler/http" = "zen-beta.desktop";
        "x-scheme-handler/https" = "zen-beta.desktop";
        "x-scheme-handler/chrome" = "zen-beta.desktop";
        "text/html" = "zen-beta.desktop";
        "application/x-extension-htm" = "zen-beta.desktop";
        "application/x-extension-html" = "zen-beta.desktop";
        "application/x-extension-shtml" = "zen-beta.desktop";
        "application/xhtml+xml" = "zen-beta.desktop";
        "application/x-extension-xhtml" = "zen-beta.desktop";
        "application/x-extension-xht" = "zen-beta.desktop";
      };
    };
  };

  imports = [
    ../../programs/zsh/default.nix
    ../../programs/neovim/default.nix
    ../../programs/git.nix
    ../../programs/direnv.nix
  ];
}
