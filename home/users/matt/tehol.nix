{ pkgs, ... }:
{
  imports = [
    ./common.nix
    ./common-work.nix
    ../../programs/recording.nix
  ];
}
