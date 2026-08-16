{
  lib,
  rustPlatform,
  tailscale,
  makeWrapper,
}:

rustPlatform.buildRustPackage {
  pname = "taildrop-syncd";
  version = "0.1.0";

  # A fileset keeps the cargo target directory out of the store, so a local
  # `cargo build` never changes the derivation hash.
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ makeWrapper ];

  # The daemon shells out to `tailscale status --json` to find peers.
  postInstall = ''
    wrapProgram $out/bin/taildrop-syncd \
      --prefix PATH : ${lib.makeBinPath [ tailscale ]}
  '';

  meta = {
    description = "Peer-to-peer sync daemon for one shared text buffer across a tailnet";
    mainProgram = "taildrop-syncd";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
