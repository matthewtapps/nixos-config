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
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  home.file = {
    ".hushlogin".text = "";
  };

  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      "kruppe" = {
        user = "matt";
      };
      "karsa" = {
        user = "matt";
      };
      "mappo" = {
        user = "matt";
      };
    };
  };

  # Clipboard sync scripts
  home.file.".local/bin/pbcopy" = {
    text = ''
      #!/usr/bin/env bash
      data=$(cat)
      if [ -n "$WAYLAND_DISPLAY" ]; then
        echo "$data" | wl-copy
      else
        echo "$data" | xclip -selection clipboard
      fi
      printf "\033]52;c;%s\a" "$(echo -n "$data" | base64 | tr -d '\n')"
    '';
    executable = true;
  };

  home.file.".local/bin/pbpaste" = {
    text = ''
      #!/usr/bin/env bash
      if [ -n "$WAYLAND_DISPLAY" ]; then
        wl-paste
      else
        xclip -o -selection clipboard
      fi
    '';
    executable = true;
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
    feh

    # Gurps
    gcs

    libreoffice
    spotify
    vlc
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
    brightnessctl
    dart-sass
    inputs.matugen.packages.${system}.default
    fd
    dconf
    hyprlock
    hyprpaper
    hyprshot
    wf-recorder
    slurp
    playerctl
    pavucontrol
    overskride
    libqalculate
    usbutils
    gnumake

    remmina
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
        # Directories
        "inode/directory" = "thunar.desktop";

        # PDFs
        "application/pdf" = "org.pwmt.zathura-cb.desktop";

        # Images - feh
        "image/jpeg" = "feh.desktop";
        "image/png" = "feh.desktop";
        "image/gif" = "feh.desktop";
        "image/bmp" = "feh.desktop";
        "image/webp" = "feh.desktop";
        "image/tiff" = "feh.desktop";
        "image/svg+xml" = "feh.desktop";

        # Text/Code files - NeoVim in WezTerm
        "text/plain" = "nvim-terminal.desktop";
        "text/x-shellscript" = "nvim-terminal.desktop";
        "application/json" = "nvim-terminal.desktop";
        "application/xml" = "nvim-terminal.desktop";
        "text/x-python" = "nvim-terminal.desktop";
        "text/x-rust" = "nvim-terminal.desktop";
        "text/x-c" = "nvim-terminal.desktop";
        "text/x-c++" = "nvim-terminal.desktop";
        "text/x-lua" = "nvim-terminal.desktop";
        "text/markdown" = "nvim-terminal.desktop";
        "text/x-yaml" = "nvim-terminal.desktop";
        "text/x-toml" = "nvim-terminal.desktop";
        "application/x-yaml" = "nvim-terminal.desktop";
        "application/toml" = "nvim-terminal.desktop";

        # Browser
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
        # Directories
        "inode/directory" = "thunar.desktop";

        # PDFs
        "application/pdf" = "org.pwmt.zathura-cb.desktop";

        # Images - feh
        "image/jpeg" = "feh.desktop";
        "image/png" = "feh.desktop";
        "image/gif" = "feh.desktop";
        "image/bmp" = "feh.desktop";
        "image/webp" = "feh.desktop";
        "image/tiff" = "feh.desktop";
        "image/svg+xml" = "feh.desktop";

        # Text/Code files - NeoVim in WezTerm
        "text/plain" = "nvim-terminal.desktop";
        "text/x-shellscript" = "nvim-terminal.desktop";
        "application/json" = "nvim-terminal.desktop";
        "application/xml" = "nvim-terminal.desktop";
        "text/x-python" = "nvim-terminal.desktop";
        "text/x-rust" = "nvim-terminal.desktop";
        "text/x-c" = "nvim-terminal.desktop";
        "text/x-c++" = "nvim-terminal.desktop";
        "text/x-lua" = "nvim-terminal.desktop";
        "text/markdown" = "nvim-terminal.desktop";
        "text/x-yaml" = "nvim-terminal.desktop";
        "text/x-toml" = "nvim-terminal.desktop";
        "application/x-yaml" = "nvim-terminal.desktop";
        "application/toml" = "nvim-terminal.desktop";

        # Browser
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
