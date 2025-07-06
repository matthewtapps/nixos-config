{
  pkgs,
  device,
  ...
}:
{
  # home.file.".zshrc" = {
  #   source = ./.zshrc;
  # };

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    plugins = [
      {
        name = "F-Sy-H";
        src = pkgs.fetchFromGitHub {
          owner = "z-shell";
          repo = "F-Sy-H";
          rev = "v1.67";
          sha256 = "zhaXjrNL0amxexbZm4Kr5Y/feq1+2zW0O6eo9iZhmi0=";
        };
      }
      {
        name = "powerlevel10k";
        src = pkgs.fetchFromGitHub {
          owner = "romkatv";
          repo = "powerlevel10k";
          rev = "35833ea15f14b71dbcebc7e54c104d8d56ca5268";
          sha256 = "ES5vJXHjAKw/VHjWs8Au/3R+/aotSbY7PWnWAMzCR8E=";
        };
      }
      {
        name = "zsh-autocomplete";
        src = pkgs.fetchFromGitHub {
          owner = "marlonrichert";
          repo = "zsh-autocomplete";
          rev = "6d059a3634c4880e8c9bb30ae565465601fb5bd2";
          sha256 = "0NW0TI//qFpUA2Hdx6NaYdQIIUpRSd0Y4NhwBbdssCs=";

        };
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "a411ef3e0992d4839f0732ebeb9823024afaaaa8";
          sha256 = "KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
        };
      }
      {
        name = "zsh-nix-shell";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "8b86281cf9e9ef9f207433dd8b36d157dd48d50a";
          sha256 = "Z6EYQdasvpl1P78poj9efnnLj7QQg13Me8x1Ryyw+dM=";
        };
      }
      {
        name = "zsh-vi-mode";
        src = pkgs.fetchFromGitHub {
          owner = "jeffreytse";
          repo = "zsh-vi-mode";
          rev = "ea1f58ab9b1f3eac50e2cde3e3bc612049ef683b";
          sha256 = "xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
        };
      }
    ];

    initContent = ''
      ${builtins.readFile ./zsh.conf}
	alias nixswitch="sudo nixos-rebuild switch --flake $HOME/nixos-config#${device}"                     # nixswitch = NixOS system switch
	alias hmswitch="nix run $HOME/nixos-config#homeConfigurations.$USER@${device}.activationPackage"     # hmswitch  = User config switch
    '';
  };

  # environment.pathsToLink = [ "/share/zsh" ];

  home.file.".zsh/plugins/custom/.p10k.zsh" = {
    source = ./plugins/custom/.p10k.zsh;
  };
}
