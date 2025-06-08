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
      open = false;
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
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
        mangohud # Gaming overlay for monitoring
      ];

      extraPackages32 = with pkgs.pkgsi686Linux; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
        mangohud # 32-bit support for older games
      ];
    };
  };

  environment.sessionVariables = {
    # NVIDIA GPU acceleration (ensures games use GPU)
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __NV_PRIME_RENDER_OFFLOAD = "1";

    # Gaming performance optimizations
    __GL_SYNC_TO_VBLANK = "0"; # Disable vsync for better performance
    __GL_VRR_ALLOWED = "1"; # Enable variable refresh rate

    # Steam/gaming compatibility
    STEAM_FORCE_DESKTOPUI_SCALING = "1";
    SDL_VIDEODRIVER = "x11"; # Better game compatibility
  };

  # Kernel parameters for better gaming performance
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  services.xserver.videoDrivers = [
    "nvidia"
  ];
}
