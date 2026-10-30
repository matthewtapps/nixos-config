{ pkgs, ... }:
{
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      # GE-Proton ships Wine's Wayland driver; Proton Experimental does not.
      # ponytail: pinned ahead of nixpkgs (11-7) for the Hyprland minimise fix;
      # drop the override once nixpkgs reaches GE-Proton11-10.
      extraCompatPackages = [
        (pkgs.proton-ge-bin.overrideAttrs {
          version = "GE-Proton11-11";
          toolName = "GE-Proton11-11-x86_64";
          src = pkgs.fetchzip {
            url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton11-11/GE-Proton11-11-x86_64.tar.gz";
            hash = "sha256-3tVgf83IkteFtVo/bHd4yG1xCtPeuW8FXaTrHOLjvKQ=";
          };
        })
      ];
    };
    gamescope.enable = true;
  };
}
