_: {
  imports = [
    ./common.nix
    ./common-personal.nix
    # ../../programs/azure-vpn.nix
    # ../../programs/claude-desktop.nix
  ];

  # Noctalia lock screen uses this PAM service — must match the one with fprintAuth = true
  home.sessionVariables.NOCTALIA_PAM_SERVICE = "noctalia";
}
