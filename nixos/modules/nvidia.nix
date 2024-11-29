{
  config,
  pkgs,
  inputs,
  ...
}:
let
  pkgs-unstable = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.nvidia_x11_beta ];
    initrd.kernelModules = [ "nvidia" ];

    kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia-drm.modeset=1"
    ];
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
      package = pkgs-unstable.mesa.drivers;

      enable32Bit = true;
      package32 = pkgs-unstable.pkgsi686Linux.mesa.drivers;
    };
  };

  services.xserver.videoDrivers = [
    "nvidia"
  ];
}
