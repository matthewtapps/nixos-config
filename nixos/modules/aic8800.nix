{ pkgs, config, ... }:

{
  # AIC8800 USB WiFi kernel module.
  # Available for udev to autoload when the USB device is plugged in. Not
  # preloaded — the OOT driver crashes on USB disconnect (cmd queue crashes
  # observed in pstore, 2026-04 and 2026-05), so we avoid keeping it
  # resident when the adapter isn't present.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage ../packages/aic8800.nix { })
  ];

  # AIC8800 firmware
  hardware.firmware = [
    (pkgs.callPackage ../packages/aic8800-firmware.nix { })
  ];

  # usb_modeswitch to switch AIC8800 from storage mode to WiFi mode
  environment.systemPackages = [ pkgs.usb-modeswitch ];
  services.udev.extraRules = ''
    # AIC8800 USB WiFi: switch from mass storage mode (a69c:5724) to WiFi mode
    ATTR{idVendor}=="a69c", ATTR{idProduct}=="5724", RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -KQ -v a69c -p 5724"
  '';
}
