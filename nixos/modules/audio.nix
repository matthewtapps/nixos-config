{ pkgs, ... }:

let
  # Work around a race condition where WirePlumber enumerates the Intel SOF
  # audio device before its firmware has finished initializing, resulting in
  # an empty profile list and only a dummy output sink.
  pipewire-sof-recovery = pkgs.writeShellScript "pipewire-sof-recovery" ''
    for i in $(seq 1 18); do
      sleep 10
      if ${pkgs.wireplumber}/bin/wpctl status | grep -q "Dummy Output"; then
        echo "SOF audio race condition detected, restarting PipeWire stack..."
        systemctl --user restart wireplumber pipewire pipewire-pulse
        exit 0
      fi
    done
  '';
in
{
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

  systemd.user.services.pipewire-sof-audio-recovery = {
    description = "Recover PipeWire audio from SOF firmware race condition";
    after = [ "pipewire.service" "wireplumber.service" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pipewire-sof-recovery;
    };
  };

  environment.systemPackages = with pkgs; [ pulseaudio ];
}
