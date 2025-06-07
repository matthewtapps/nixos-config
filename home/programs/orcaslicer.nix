{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "orca-slicer" ''
      export __GLX_VENDOR_LIBRARY_NAME=mesa
      export __EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json
      export MESA_LOADER_DRIVER_OVERRIDE=zink
      export GALLIUM_DRIVER=zink
      export WEBKIT_DISABLE_DMABUF_RENDERER=1
      export MESA_GL_VERSION_OVERRIDE=4.5
      export MESA_GLSL_VERSION_OVERRIDE=450
      export ZINK_DESCRIPTORS=lazy
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
