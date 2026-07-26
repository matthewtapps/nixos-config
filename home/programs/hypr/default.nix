{
  device,
  pkgs,
  inputs,
  ...
}:
let
  hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
in
{
  home.file."./.config/hypr/bg3.jpg" = {
    source = ./bg3.jpg;
  };

  home.file."./.config/hypr/bg4.jpg" = {
    source = ./bg4.jpg;
  };

  home.file."./.config/hypr/assets" = {
    source = ./assets/default_album.png;
  };

  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy:force_shm = 1
  '';

  # Real Lua config files, symlinked as-is. Hyprland's package.path is
  # "<configdir>/?.lua", so these are reachable as `lua.<name>`.
  xdg.configFile."hypr/lua" = {
    source = ./hyprland;
    recursive = true;
  };

  # lua-language-server picks up Hyprland's generated `hl` API stubs. Home
  # Manager only writes this itself when it manages the package, which it
  # doesn't here (the NixOS module owns Hyprland).
  xdg.configFile."hypr/.luarc.json".text = builtins.toJSON {
    workspace.library = [ "${hyprlandPkg}/share/hypr/stubs" ];
    diagnostics.globals = [ "hl" ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    portalPackage = null;
    package = null;
    extraConfig = ''
      require("lua.${device}")
      require("lua.common")
    '';
  };

  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      ${builtins.readFile ./hyprlock/${device}.conf}
      ${builtins.readFile ./hyprlock/common.conf}
    '';
  };

  home.packages = with pkgs; [
    imagemagick
    (writeShellScriptBin "music-info" ''
      ${builtins.readFile ./scripts/music-info}
    '')
    (writeShellScriptBin "record-region-toggle" ''
      ${builtins.readFile ./scripts/record-region-toggle.sh}
    '')
  ];
}
