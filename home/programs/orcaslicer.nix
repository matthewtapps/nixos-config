{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "orca-slicer" ''
      export WEBKIT_DISABLE_DMABUF_RENDERER=1
      export GDK_BACKEND=x11
      export QT_QPA_PLATFORM=xcb
      exec ${pkgs.orca-slicer}/bin/orca-slicer "$@"
    '')
  ];

  xdg.desktopEntries.orca-slicer = {
    name = "OrcaSlicer";
    comment = "3D Printer Slicer Software";
    exec = "orca-slicer %F";
    icon = "orca-slicer";
    terminal = false;
    type = "Application";
    mimeType = [
      "model/stl"
      "application/sla"
      "model/x.stl-ascii"
      "model/x.stl-binary"
      "model/3mf"
      "application/3mf"
    ];
  };
}
