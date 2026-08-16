{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    cachix
  ];

  nix = {
    settings = {
      # cache.nixos.org + its key are provided by the NixOS defaults; listing
      # them here again only duplicates the entries in the generated nix.conf.
      substituters = [
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://neovim.cachix.org"
        "https://claude-code.cachix.org"
        "http://192.168.0.194:5000"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "neovim.cachix.org-1:iyQ3Blw1uJODzY8+LXkDBnCpulPGrqJ+mOQGpok6Iyw="
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
        "karsa:iL+1/w7TWoG4Xs4uFNTyTyprMtS1T4FAAfxwAr487Og="
      ];

      connect-timeout = 5;
      fallback = true;

      max-jobs = "auto";
      cores = 0;
      system-features = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];

      # experimental-features is set in nix-options.nix; don't duplicate it here.

      use-xdg-base-directories = true;
      # Inline hard-linking on every store write serialises builds and leaves
      # the daemon in uninterruptible-sleep (D) with the CPU idle. nix.optimise
      # in nix-options.nix does it out of band.
      auto-optimise-store = false;
    };
  };
}
