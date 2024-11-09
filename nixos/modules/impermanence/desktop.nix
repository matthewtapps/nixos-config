{ ... }: {
  environment.persistence."/persist/system" = {
    directories =
      [ "/etc/ssh" "/etc/nixos" "/var/log" "/var/lib" "/var/lib/nixos" ];
    files = [ "/etc/machine-id" "/etc/termin-monitor" ];
    users.matt = {
      directories = [
        {
          directory = ".config/discord";
          mode = "0700";
          user = "matt";
        }
        {
          directory = ".config/systemd";
          user = "matt";
        }
        {
          directory = ".config/spotify";
          user = "matt";
        }
        {
          directory = ".config/Signal";
          user = "matt";
        }
        {
          directory = ".config/github-copilot";
          user = "matt";
        }
        {
          directory = ".config/vlc";
          user = "matt";
        }
        {
          directory = ".local/share/direnv";
          user = "matt";
        }
        {
          directory = ".local/share/keyrings";
          user = "matt";
        }
        {
          directory = ".local/share/nvim";
          user = "matt";
        }
        {
          directory = ".local/share/Steam";
          user = "matt";
        }
        {
          directory = ".local/state/nix";
          mode = "0700";
          user = "matt";
        }
        {
          directory = ".ssh";
          user = "matt";
        }
        {
          directory = "nixos-config";
          user = "matt";
        }
        {
          directory = "workspace";
          user = "matt";
        }
      ];
      files = [{ file = ".zsh_history"; }];
    };
  };
  fileSystems."/persist".neededForBoot = true;

  programs.fuse.userAllowOther = true; # requied for home-manager impermanence

  security.sudo.extraConfig = ''
    # rollback results in sudo lectures after each reboot
    Defaults lecture = never
  '';
}
