{ pkgs, inputs, ... }:
{
  services = {
    greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd Hyprland";
          user = "matt";
        };
        default_session = initial_session;
        Type = "idle";
        StandardInput = "tty";
        StandardOutput = "tty";
        StandardError = "journal";
        TTYReset = true;
        TTYVHangup = true;
        TTYVTDisallocate = true;
        After = [
          "docker.service"
          "bluetooth.service"
        ];
      };
    };
  };

  systemd.services.greetd = {
    serviceConfig = {
      Type = "idle";
    };
    unitConfig = {
      After = [ "multi-user.target" ];

    };
  };

  environment.sessionVariables = {
    NIXOS_OZONE_LAYER = "1";
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };
}
