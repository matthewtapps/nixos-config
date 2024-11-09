{ pkgs, ... }: {
  # environment.systemPackages = with pkgs; [ docker ];

  users.users.matt.extraGroups = [ "docker" ];

  virtualisation.docker.enable = true;
  virtualisation.docker.liveRestore = false;
}
