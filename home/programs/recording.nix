{ pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      # Per-application / clean microphone audio capture on PipeWire.
      obs-pipewire-audio-capture
    ];
  };

  # Non-linear editor for cutting the OBS recording afterward.
  home.packages = [ pkgs.kdePackages.kdenlive ];
}
