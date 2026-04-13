{ pkgs, config, ... }:

{
  # AIC8800 USB WiFi kernel module
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage ../packages/aic8800.nix { })
  ];
  boot.kernelModules = [ "aic8800_fdrv" "aic_load_fw" ];

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
