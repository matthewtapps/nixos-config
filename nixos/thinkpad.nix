{ config, lib, pkgs, nixos-wsl, ... }:
{
  imports = [
    # include NixOS-WSL modules
    ./modules/common.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "matt";
  
  programs = {
    zsh = {
      enable = true;
      enableCompletion = false;
    };
    nix-ld = {
      enable = true;
      libraries = with pkgs; [ stdenv.cc.cc ];
    };

  };

  environment = {
    sessionVariables = { NIXOS_OZONE_WL = "1"; };
    systemPackages = with pkgs; [ openssl xfce.thunar bun gcc ];
  };
  

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
