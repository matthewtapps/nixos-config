{
  config,
  pkgs,
  inputs,
  lib,
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

  home.file.".config/matt.jpg" = {
    source = ./matt.jpeg;
  };

  home.file.".config/lazygit/config.yml".text = ''
    disableStartupPopups: true
  '';

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
    feh

    libreoffice
    vlc
    btop
    fastfetch
    obsidian
    vscode
    signal-desktop
    spotify-player
    thunar
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
    jq

    claude-code
    tree
    thunderbird
    aerc
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

    # Create custom desktop entries
    desktopEntries = {
      nvim-terminal = {
        name = "Neovim (Terminal)";
        genericName = "Text Editor";
        comment = "Edit text files in Neovim within WezTerm";
        exec = "wezterm start -- nvim %F";
        icon = "nvim";
        terminal = false;
        categories = [
          "Utility"
          "TextEditor"
          "Development"
        ];
        mimeType = [
          "text/plain"
          "text/x-shellscript"
          "application/json"
          "application/xml"
          "text/x-python"
          "text/x-rust"
          "text/x-c"
          "text/x-c++"
          "text/x-lua"
          "text/markdown"
          "text/x-yaml"
          "text/x-toml"
          "application/x-yaml"
          "application/toml"
          "text/x-nix"
          "application/javascript"
          "text/x-java"
          "text/css"
          "text/x-go"
          "application/x-shellscript"
        ];
      };

};

    mime.enable = true;
    mimeApps = {
      enable = true;

      associations.removed = {
        # Remove ALL Calibre applications from document types
        "application/vnd.oasis.opendocument.text" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "application/msword" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "application/vnd.ms-word.document.macroEnabled.12" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "application/rtf" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "application/vnd.oasis.opendocument.spreadsheet" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "application/vnd.ms-excel" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "application/vnd.oasis.opendocument.presentation" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "application/vnd.ms-powerpoint" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "application/pdf" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "text/plain" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
        "text/html" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
      };

      associations.added = {
        # Directories
        "inode/directory" = "thunar.desktop";

        # PDFs
        "application/pdf" = "org.pwmt.zathura.desktop";

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
        "text/x-nix" = "nvim-terminal.desktop";
        "application/javascript" = "nvim-terminal.desktop";
        "text/css" = "nvim-terminal.desktop";

        # LibreOffice Writer - Word documents
        "application/vnd.oasis.opendocument.text" = "libreoffice-writer.desktop";
        "application/vnd.oasis.opendocument.text-template" = "libreoffice-writer.desktop";
        "application/msword" = "libreoffice-writer.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
          "libreoffice-writer.desktop";
        "application/vnd.ms-word.document.macroEnabled.12" = "libreoffice-writer.desktop";
        "application/rtf" = "libreoffice-writer.desktop";

        # LibreOffice Calc - Spreadsheets
        "application/vnd.oasis.opendocument.spreadsheet" = "libreoffice-calc.desktop";
        "application/vnd.oasis.opendocument.spreadsheet-template" = "libreoffice-calc.desktop";
        "application/vnd.ms-excel" = "libreoffice-calc.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "libreoffice-calc.desktop";
        "application/vnd.ms-excel.sheet.macroEnabled.12" = "libreoffice-calc.desktop";
        "text/csv" = "libreoffice-calc.desktop";

        # LibreOffice Impress - Presentations
        "application/vnd.oasis.opendocument.presentation" = "libreoffice-impress.desktop";
        "application/vnd.oasis.opendocument.presentation-template" = "libreoffice-impress.desktop";
        "application/vnd.ms-powerpoint" = "libreoffice-impress.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
          "libreoffice-impress.desktop";
        "application/vnd.ms-powerpoint.presentation.macroEnabled.12" = "libreoffice-impress.desktop";

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
        "application/pdf" = "org.pwmt.zathura.desktop";

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
        "text/x-nix" = "nvim-terminal.desktop";
        "application/javascript" = "nvim-terminal.desktop";
        "text/css" = "nvim-terminal.desktop";

        # LibreOffice Writer - Word documents
        "application/vnd.oasis.opendocument.text" = "libreoffice-writer.desktop";
        "application/vnd.oasis.opendocument.text-template" = "libreoffice-writer.desktop";
        "application/msword" = "libreoffice-writer.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
          "libreoffice-writer.desktop";
        "application/vnd.ms-word.document.macroEnabled.12" = "libreoffice-writer.desktop";
        "application/rtf" = "libreoffice-writer.desktop";

        # LibreOffice Calc - Spreadsheets
        "application/vnd.oasis.opendocument.spreadsheet" = "libreoffice-calc.desktop";
        "application/vnd.oasis.opendocument.spreadsheet-template" = "libreoffice-calc.desktop";
        "application/vnd.ms-excel" = "libreoffice-calc.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "libreoffice-calc.desktop";
        "application/vnd.ms-excel.sheet.macroEnabled.12" = "libreoffice-calc.desktop";
        "text/csv" = "libreoffice-calc.desktop";

        # LibreOffice Impress - Presentations
        "application/vnd.oasis.opendocument.presentation" = "libreoffice-impress.desktop";
        "application/vnd.oasis.opendocument.presentation-template" = "libreoffice-impress.desktop";
        "application/vnd.ms-powerpoint" = "libreoffice-impress.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
          "libreoffice-impress.desktop";
        "application/vnd.ms-powerpoint.presentation.macroEnabled.12" = "libreoffice-impress.desktop";

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

  home.activation.createCustomDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${config.home.homeDirectory}/screenshots
  '';

  imports = [
    ../../programs/zsh/default.nix
    ../../programs/neovim/default.nix
    ../../programs/git.nix
    ../../programs/direnv.nix
    ../../programs/zathura.nix
  ];
}
