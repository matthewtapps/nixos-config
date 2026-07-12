{ pkgs, inputs, ... }: {
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    package = pkgs.nixVersions.latest;
    registry.nixpkgs.flake = inputs.nixpkgs;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
    # Replaces inline auto-optimise-store (see cachix.nix): dedupe the store on a
    # timer instead of stalling every build on hard-linking.
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };
}
