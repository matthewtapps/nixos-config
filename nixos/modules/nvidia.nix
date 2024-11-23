{ config, pkgs, ... }:
{
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.nvidia_x11_beta ];
    initrd.kernelModules = [ "nvidia" ];

    kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
  };

  environment.systemPackages = with pkgs; [
    linuxPackages.nvidia_x11
  ];

  hardware = {
    nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      powerManagement.enable = false;
    };

    graphics = {
      enable = true;
    };

    system76 = {
      enableAll = true;
      kernel-modules.enable = true;
    };
  };

  services.xserver.videoDrivers = [
    "nvidia"
  ];
}
