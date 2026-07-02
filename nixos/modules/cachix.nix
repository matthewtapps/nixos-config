# nixos/modules/cachix.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    cachix
  ];

  nix = {
    settings = {
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://neovim.cachix.org"
        "https://claude-code.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "neovim.cachix.org-1:iyQ3Blw1uJODzY8+LXkDBnCpulPGrqJ+mOQGpok6Iyw="
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      ];

      max-jobs = "auto";
      cores = 0;
      system-features = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      use-xdg-base-directories = true;
      auto-optimise-store = true;

    };
  };
}
