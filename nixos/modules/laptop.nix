{ pkgs, ... }: {
  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "auto";
        energy_performance_preference = "power";
      };
      charger = {
        # amd-pstate-epp: "powersave" is the DYNAMIC governor (full turbo under
        # load, clocks down at idle). "performance" pins max clock+voltage even
        # idle -> constant heat + fan never rests while on AC.
        governor = "powersave";
        turbo = "auto";
        energy_performance_preference = "balance_performance";
      };
    };
  };

  services.upower = {
    enable = true;
    ignoreLid = true;
  };

  # Let Noctalia handle sleep/lock on lid close
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  services.devmon.enable = true;
  services.udisks2.enable = true;

  hardware.rasdaemon.enable = true;

  services.fwupd.enable = true;

  # Fingerprint reader. Noctalia claims the sensor through fprintd's D-Bus API
  # and authenticates passwords against the login PAM service, so no noctalia
  # PAM service is needed. Leave login.fprintAuth off: it would put the sensor
  # in the TTY login path and compete for the device with that claim.
  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = false;
  security.pam.services.greetd.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;

  environment.systemPackages = with pkgs; [ powertop ];
}
