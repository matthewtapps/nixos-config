{ lib, ... }:
{
  imports = [
    ./common.nix
  ];

  # Headless: stylix's xfce target writes xfconf properties, and activation
  # fails without a running xfconfd.
  stylix.targets.xfce.enable = lib.mkForce false;
}
