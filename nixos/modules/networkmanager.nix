{ lib, ... }: {
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = lib.mkForce [ ];
}
