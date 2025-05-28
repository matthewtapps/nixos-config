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
      open = false;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
    };

    graphics = {
      enable = true;
      package = pkgs-unstable.mesa;

      enable32Bit = true;
      package32 = pkgs-unstable.pkgsi686Linux.mesa;
    };
  };

  services.xserver.videoDrivers = [
    "nvidia"
  ];
}
