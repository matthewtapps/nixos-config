{ pkgs, ... }:
{
  services = {
    printing.enable = true;
    geoclue2.enable = true;
  };

  environment = {
    variables = {
      EDITOR = "nvim";
    };
    systemPackages = with pkgs; [
      neovim
      wget
      git
      gh
      chezmoi
      curl
      lazygit
      lazydocker
      bash
      rbw
      pinentry-curses
      ssh-to-age
      sops
      wol
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Restarting dbus-broker during switch deadlocks — changes take effect on next login/reboot
  systemd.user.services.dbus-broker.restartIfChanged = false;

  services.envfs.enable = true;

  services.udev.packages = [ pkgs.openocd ];
  users.users.matt.extraGroups = [ "dialout" ];

  imports = [
    ./ssh.nix
    ./user.nix
    ./fonts.nix
    ./locale.nix
    ./nix-options.nix
    ./linux-kernel.nix
    ./cachix.nix
    ./tailscale.nix
  ];
}
