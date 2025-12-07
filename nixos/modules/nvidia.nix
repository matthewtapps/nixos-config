{
  config,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    linuxPackages.nvidia_x11
  ];

  hardware = {
    nvidia = {
      modesetting.enable = true;
      open = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
      forceFullCompositionPipeline = false; # Better for gaming performance
    };

    graphics = {
      enable = true;
      package = pkgs.mesa;
      enable32Bit = true;
      package32 = pkgs.pkgsi686Linux.mesa;

      extraPackages = with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];

      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva-vdpau-driver
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };
  };

  # Kernel parameters for better gaming performance
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];
}
