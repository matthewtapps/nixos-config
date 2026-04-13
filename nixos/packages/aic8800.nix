{
  lib,
  pkgs,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
}:

stdenv.mkDerivation {
  pname = "aic8800";
  version = "0-unstable-2025-05-18";

  src = fetchFromGitHub {
    owner = "susers";
    repo = "aic8800_linux_drvier";
    rev = "b7725e82459eddf2e3b4dd632e7be2e8ba006100";
    hash = "sha256-uYS364mD9QcugbKtIDqJKouq4y4xKXeqZjswkABrg0M=";
  };

  sourceRoot = "source/drivers/aic8800";

  postPatch = ''
    # in_irq() was removed in recent kernels, replaced by in_hardirq()
    substituteInPlace aic8800_fdrv/rwnx_rx.c \
      --replace-warn "in_irq()" "in_hardirq()"

    # Use kernel request_firmware() API instead of hardcoded /lib/firmware paths.
    # This is required on NixOS where firmware lives in /run/current-system/firmware/
    # and may be zstd-compressed (which request_firmware handles transparently).
    substituteInPlace Makefile \
      --replace-warn "export CONFIG_USE_FW_REQUEST = n" "export CONFIG_USE_FW_REQUEST = y"

    # Add USB PID 0x8D88 (UGREEN WiFi 6 adapter, AIC8800D80 chipset).
    # Upstream doesn't include this PID yet; confirmed by shenmintao/aic8800d80 fork.
    substituteInPlace aic8800_fdrv/aicwf_usb.h \
      --replace-warn \
        "#define USB_PRODUCT_ID_AIC8800D89X2     0x8d99" \
        "#define USB_PRODUCT_ID_AIC8800D89X2     0x8d99
#define USB_PRODUCT_ID_AIC8800D80_UGREEN 0x8d88"

    # Add UGREEN PID to USB ID table (after D89X2 entry)
    sed -i '/{USB_DEVICE(USB_VENDOR_ID_AIC_V2, USB_PRODUCT_ID_AIC8800D89X2)},/a\    {USB_DEVICE(USB_VENDOR_ID_AIC_V2, USB_PRODUCT_ID_AIC8800D80_UGREEN)},' \
      aic8800_fdrv/aicwf_usb.c

    # Add UGREEN PID to chipmatch function (after D89X2 block, before final else)
    sed -i '/USE AIC8800D89X2/,/return 0;/{
      /return 0;/a\    }else if(pid == USB_PRODUCT_ID_AIC8800D80_UGREEN){\
        usb_dev->chipid = PRODUCT_ID_AIC8800D81;\
        aicwf_usb_rx_aggr = true;\
        AICWFDBG(LOGINFO, "%s USE AIC8800D80 (UGREEN)\\r\\n", __func__);\
        return 0;
    }' aic8800_fdrv/aicwf_usb.c
  '';

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  buildPhase = ''
    runHook preBuild

    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$(pwd) \
      KCFLAGS="-w" \
      $makeFlags \
      modules

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/aic8800
    find . -name "*.ko" -exec install {} -Dm444 -v -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/aic8800 \;

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/susers/aic8800_linux_drvier";
    description = "Aicsemi AIC8800 Wi-Fi driver (USB)";
    license = with lib.licenses; [ gpl2Only ];
    platforms = lib.platforms.linux;
  };
}
