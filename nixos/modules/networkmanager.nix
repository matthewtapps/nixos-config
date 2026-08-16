{ lib, ... }: {
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = lib.mkForce [ ];

  # The default stop-then-start leaves the link down until the start phase of
  # switch-to-configuration, stranding deploys that arrive over the tailnet.
  systemd.services.NetworkManager.stopIfChanged = false;
}
