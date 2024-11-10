{pkgs, ...}: {
  users.users.matt = {
    isNormalUser = true;
    description = "matt";
    extraGroups = [ "wheel" "networkmanager" "video" ];
    shell = pkgs.zsh;
  };
}
