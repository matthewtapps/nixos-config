{ pkgs, ... }:
{
  imports = [
    ./common.nix
    ./common-work.nix
  ];

  # Noctalia lock screen uses this PAM service — must match the one with fprintAuth = true
  home.sessionVariables.NOCTALIA_PAM_SERVICE = "noctalia";
}
