{ pkgs, ... }: {
  imports = [
    ./common.nix
#    ./theme.nix
    ];
    
#   home.packages = with pkgs; [
#     fd
#     dconf
#   ];

    home.stateVersion = "24.05";
    
    home.file = { ".hushlogin".text = ""; };
    services.ssh-agent.enable = true;

    programs.ssh = { enable = true; };
}
