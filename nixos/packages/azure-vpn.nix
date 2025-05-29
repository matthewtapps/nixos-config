# Update your nixos/packages/azure-vpn.nix to just be the direct binary:

{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  openssl,
  gtk3,
  libsecret,
  cairo,
  nss,
  nspr,
  libuuid,
  at-spi2-core,
  libdrm,
  mesa,
  gtk2,
  glib,
  pango,
  atk,
  curl,
  zenity,
  cacert,
  openvpn,
  libcap,
}:

stdenv.mkDerivation rec {
  pname = "microsoft-azurevpnclient";
  version = "3.0.0";

  src = fetchurl {
    url = "https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/microsoft-azurevpnclient/microsoft-azurevpnclient_${version}_amd64.deb";
    hash = "sha256-nl02BDPR03TZoQUbspplED6BynTr6qNRVdHw6fyUV3s=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    libcap
  ];

  buildInputs = [
    zenity
    openssl
    gtk3
    libsecret
    cairo
    nss
    nspr
    libuuid
    stdenv.cc.cc.lib
    at-spi2-core
    libdrm
    mesa
    gtk2
    glib
    pango
    atk
    curl
    cacert
    openvpn
  ];

  runtimeDependencies = [ zenity ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out
    cp -r opt $out
    cp -r usr/* $out

    mkdir -p $out/bin
    ln -s $out/opt/microsoft/microsoft-azurevpnclient/microsoft-azurevpnclient $out/bin/microsoft-azurevpnclient
    ln -s $out/opt/microsoft/microsoft-azurevpnclient/lib $out

    wrapProgram $out/bin/microsoft-azurevpnclient \
      --prefix SSL_CERT_DIR : "${cacert.unbundled}/etc/ssl/certs" \
      --prefix PATH : "${zenity}/bin" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --prefix LD_LIBRARY_PATH : "$out/lib"

    mkdir -p $out/share/applications
    if [ -f usr/share/applications/azurevpnclient.desktop ]; then
      cp usr/share/applications/azurevpnclient.desktop $out/share/applications/
    fi
  '';

  meta = with lib; {
    description = "Microsoft Azure VPN Client";
    homepage = "https://azure.microsoft.com/en-us/services/vpn-gateway/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
