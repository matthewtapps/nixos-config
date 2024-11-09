{ pkgs, ... }: {
  services = {
    printing.enable = true;
    geoclue2.enable = true;
  };

  environment = {
    variables = { EDITOR = "nvim"; };
    systemPackages = with pkgs; [ neovim wget git gh chezmoi curl ];
  };

  imports = [
    ./ssh.nix
    ./user.nix
    ./fonts.nix
    ./locale.nix
    ./thunar.nix
    ./nix-options.nix
    ./linux-kernel.nix
    ./networkmanager.nix
  ];
}
