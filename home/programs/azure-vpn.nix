{
  config,
  lib,
  ...
}:

{
  # Create desktop entry for the application launcher
  xdg.desktopEntries.azure-vpn = {
    name = "Azure VPN Client";
    comment = "Microsoft Azure VPN Client";
    exec = "microsoft-azurevpnclient";
    icon = "network-vpn";
    categories = [
      "Network"
      "Security"
    ];
    terminal = false;
    type = "Application";
    startupNotify = true;
  };

  # Optional: Add shell aliases for command line usage
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    azurevpn = "microsoft-azurevpnclient";
    avpn = "microsoft-azurevpnclient";
  };

  programs.bash.shellAliases = lib.mkIf config.programs.bash.enable {
    azurevpn = "microsoft-azurevpnclient";
    avpn = "microsoft-azurevpnclient";
  };
}
