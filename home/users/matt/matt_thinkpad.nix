_: {
  imports = [
    ./common.nix
  ];

  home.stateVersion = "24.05";

  home.file = {
    ".hushlogin".text = "";
  };
  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;
  };
}
