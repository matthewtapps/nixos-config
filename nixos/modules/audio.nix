{ pkgs, ... }:

{
  # Intel Arrow Lake cAVS / SOF (skl_hda_dsp_generic). There used to be a
  # pipewire-sof-audio-recovery service here to work around a boot race where
  # WirePlumber enumerated the card before its firmware finished, leaving only a
  # "Dummy Output" sink. Removed 2026-07-12: on kernel 7.1 + PipeWire 1.6 the SOF
  # firmware loads well before WirePlumber starts and WirePlumber reacts to udev
  # hotplug, so the race no longer reproduces. If "Dummy Output" comes back on an
  # unlucky boot, add a targeted udev-triggered check rather than a blind poll.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    extraConfig.pipewire = {
      "99-min-quantum" = {
        "context.properties" = {
          "default.clock.min-quantum" = 1024;
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ pulseaudio ];
}
