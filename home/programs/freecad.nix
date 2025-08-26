{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "freecad" ''
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
      exec ${pkgs.freecad}/bin/freecad "$@"
    '')
  ];
}
