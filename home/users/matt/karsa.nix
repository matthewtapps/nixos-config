_:
{
  imports = [
    ./common.nix
    ./common-personal.nix
    # ../../programs/azure-vpn.nix
    ../../programs/orcaslicer.nix
    ../../programs/mangohud.nix
    ../../programs/freecad.nix
  ];

  services.librespot = {
    enable = true;
    settings = {
      name = "karsa";
      backend = "pulseaudio";
      bitrate = 320;
      device-type = "computer";
    };
  };
}
