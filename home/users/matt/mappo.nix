_: {
  imports = [
    ./common.nix
    ./common-personal.nix
    ./theme.nix
    ../../programs/noctalia/mappo.nix
    ../../programs/hypr/default.nix
    ../../programs/lan-mouse.nix
    ../../programs/wezterm/default.nix
    ../../programs/azure-vpn.nix
    ../../programs/stylix.nix
    # ../../programs/claude-desktop.nix
  ];

  # Noctalia lock screen uses this PAM service — must match the one with fprintAuth = true
  home.sessionVariables.NOCTALIA_PAM_SERVICE = "noctalia";
}
