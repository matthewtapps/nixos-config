{ pkgs, ... }:
{
  users.users.matt = {
    isNormalUser = true;
    description = "matt";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
    shell = pkgs.zsh;
  };

  users.users.anna = {
    isNormalUser = true;
    description = "anna";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
    shell = pkgs.zsh;
  };
}
