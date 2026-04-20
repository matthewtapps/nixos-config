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
        governor = "performance";
        turbo = "auto";
        energy_performance_preference = "performance";
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

  # Fingerprint reader
  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = false;
  security.pam.services.greetd.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.noctalia.fprintAuth = true;

  environment.systemPackages = with pkgs; [ powertop ];
}
