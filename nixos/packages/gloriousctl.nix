{
  lib,
  stdenv,
  fetchFromGitHub,
  hidapi,
}:

stdenv.mkDerivation {
  pname = "gloriousctl";
  version = "unstable-2024-01-01";

  src = fetchFromGitHub {
    owner = "enkore";
    repo = "gloriousctl";
    rev = "ad5772fccbfffd85e69c94d17a2228191480e19f";
    hash = "sha256-lqFw6GZ5THp8kAZVxtYqoqYeoncXcr1pxEmlBCsGu6w=";
  };

  buildInputs = [ hidapi ];

  installPhase = ''
    mkdir -p $out/bin
    cp gloriousctl $out/bin/
  '';

  meta = with lib; {
    description = "CLI tool to configure Glorious Model O/D mice on Linux";
    homepage = "https://github.com/enkore/gloriousctl";
    license = licenses.eupl12;
    platforms = platforms.linux;
  };
}
