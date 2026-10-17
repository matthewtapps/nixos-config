{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  zen = import ./lib.nix { inherit pkgs config inputs; };
in
{
  programs.zen-browser.profiles = {
    Personal = lib.mkMerge [
      {
        isDefault = false;
        storeId = null;
      }
      (zen.themed "gruvbox-dark-medium")
    ];
    Work = lib.mkMerge [
      (zen.mkProfile {
        id = 2;
        path = "work";
        extensions = zen.extensions.shared ++ zen.extensions.work;
      })
      {
        isDefault = true;
        storeId = zen.storeId;
      }
    ];
  };

  stylix.targets.zen-browser.profileNames = lib.mkForce [ "Work" ];
}
