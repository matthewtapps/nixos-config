{ pkgs, ... }:
{
  services = {
    printing.enable = true;
    geoclue2.enable = true;
  };

  environment = {
    variables = {
      EDITOR = "hx";
    };
    systemPackages = with pkgs; [
      neovim
      wget
      git
      gh
      chezmoi
      curl
      lazygit
      bash
    ];
  };

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
  ];
}
