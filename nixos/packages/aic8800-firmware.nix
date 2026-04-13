{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "aic8800-firmware";
  version = "0-unstable-2025-05-18";

  src = fetchFromGitHub {
    owner = "radxa-pkg";
    repo = "aic8800";
    rev = "22a6531d1098b10966c6e5d551b61b96b5f8ddf8";
    hash = "sha256-BIJLsI823eXZv8JROWpyRbdceLX8cdZwiOkGgAQZzDE=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Install firmware files directly into lib/firmware/ (no subdirectory).
    # The driver uses request_firmware() with bare filenames when
    # CONFIG_USE_FW_REQUEST=y, so the kernel firmware loader needs to find
    # them at the root of the firmware search path.
    mkdir -p $out/lib/firmware
    cp -rv src/USB/driver_fw/fw/aic8800DC/* $out/lib/firmware/
    cp -rv src/USB/driver_fw/fw/aic8800D80/* $out/lib/firmware/

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/susers/aic8800_linux_drvier";
    description = "Aicsemi AIC8800DC Wi-Fi firmware";
    license = with lib.licenses; [ gpl2Only ];
    platforms = lib.platforms.linux;
  };
}
