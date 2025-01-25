{
  pkgs,
  ags,
  astal,
  ...
}:
{
  pkgs."x86_64-linux".default = pkgs.stdenvNoCC.mkDerivation rec {
    name = "my-shell";
    src = ./.;

    nativeBuildInputs = [
      ags.packages."x86_64-linux".default
      pkgs.wrapGAppsHook
      pkgs.gobject-introspection
    ];

    buildInputs = with astal.packages."x86_64-linux"; [
      astal3
      io
    ];

    installPhase = ''
      mkdir -p $out/bin
      ags bundle app.ts $out/bin/${name}
    '';
  };
}
