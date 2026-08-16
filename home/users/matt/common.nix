{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  programs.home-manager.enable = true;

  # sd-switch can't find previous HM generation in NixOS module mode, restarts all user services (HM #7583)
  systemd.user.startServices = false;

  home.stateVersion = "24.05";

  home.activation.report-changes = config.lib.dag.entryAnywhere ''
    if [ -n "''${oldGenPath-}" ]; then
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff $oldGenPath $newGenPath
    fi
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

  home.file.".config/lazygit/config.yml" = {
    source = ./lazygit.yml;
  };

  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "yes";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
      "kruppe" = {
        User = "matt";
        HostName = "kruppe.local";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      "karsa" = {
        User = "matt";
        HostName = "karsa.local";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      "mappo" = {
        User = "matt";
        HostName = "mappo.local";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      "tehol" = {
        User = "matt";
        HostName = "tehol.local";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      "samar" = {
        User = "matt";
        HostName = "samar.local";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      "baruk" = {
        User = "matt";
        HostName = "baruk.local";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      # The iLO4 SSH stack predates OpenSSH 8.8, which dropped SHA-1 host keys
      # and these kex, cipher and MAC suites. Without all four re-enables the
      # connection is refused during negotiation.
      "ilo" = {
        User = "Administrator";
        HostName = "10.42.0.5";
        ProxyJump = "baruk";
        PubkeyAuthentication = false;
        HostKeyAlgorithms = "+ssh-rsa";
        KexAlgorithms = "+diffie-hellman-group14-sha1";
        Ciphers = "+aes256-cbc,aes128-cbc";
        MACs = "+hmac-sha1";
      };
    };
  };

  # Clipboard sync scripts
  home.file.".local/bin/pbcopy" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Buffer to a temp file: command substitution strips trailing newlines and
      # cannot carry NUL bytes.
      tmp=$(mktemp)
      trap 'rm -f "$tmp"' EXIT
      cat >"$tmp"

      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        # --type is mandatory: bare wl-copy infers the MIME type via xdg-mime,
        # and content-sniffing misfires (e.g. text starting "FONT" is detected
        # as application/x-font-vfont) leave the clipboard unpasteable.
        wl-copy --type text/plain <"$tmp"
      elif [ -n "''${DISPLAY:-}" ]; then
        xclip -selection clipboard <"$tmp"
      fi

      # OSC 52 only matters when the terminal is remote; locally it duplicates
      # the native copy above. Matches the SSH_TTY guard in the neovim config.
      if [ -n "''${SSH_TTY:-}''${SSH_CONNECTION:-}" ]; then
        # Terminals cap the sequence at 100000 bytes, i.e. 74994 bytes of
        # payload. Oversized sequences are silently dropped, so skip instead.
        if [ "$(wc -c <"$tmp")" -le 74994 ]; then
          printf '\033]52;c;%s\a' "$(base64 <"$tmp" | tr -d '\n')" >/dev/tty 2>/dev/null || true
        else
          echo "pbcopy: input exceeds OSC 52 limit, not sent to remote terminal" >&2
        fi
      fi
    '';
    executable = true;
  };

  home.file.".local/bin/pbpaste" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      # --no-newline matches macOS pbpaste, which emits the clipboard verbatim.
      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        wl-paste --no-newline
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
    cliphist
    wl-clipboard
    iproute2
    lm_sensors
    feh

    libreoffice
    onlyoffice-desktopeditors
    vlc
    btop
    fastfetch
    obsidian
    signal-desktop
    spotify-player
    thunar
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    brightnessctl
    dart-sass
    inputs.matugen.packages.${pkgs.stdenv.hostPlatform.system}.default
    fd
    dconf
    hyprlock
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
    wirelesstools
    iw

    tree
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
        comment = "Edit text files in Neovim within Ghostty";
        exec = "ghostty -e nvim %F";
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
        # Remove all Calibre applications from document types
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
    # ../../programs/wezterm/default.nix  # kept for easy rollback
    ../../programs/zsh/version-check.nix
    ../../programs/zsh/default.nix
    ../../programs/ghostty.nix
    ../../programs/herdr/default.nix
    ../../programs/keybind-cheatsheet/default.nix
    ../../programs/neovim/default.nix
    ../../programs/git.nix
    ../../programs/claude-code.nix
    ../../programs/direnv.nix
    ../../programs/zathura.nix
    ./theme.nix
    ../../programs/hypr/default.nix
    ../../programs/noctalia/default.nix
    ../../programs/stylix.nix
  ];
}
