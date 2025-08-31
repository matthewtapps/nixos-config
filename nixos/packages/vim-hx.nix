
# Create this file at: nixos/packages/vim-hx.nix
{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, git
, installShellFiles
, makeWrapper
}:

rustPlatform.buildRustPackage rec {
  pname = "vim-hx";
  version = "unstable-2024-01-01";

  src = fetchFromGitHub {
    owner = "badranX";
    repo = "vim.hx";
    rev = "main";
    hash = "sha256-UBAOC6yqHFsg9Zt1A/WmSvvkKYyP1JD9qI3KwuKv788=";
  };

  cargoHash = "sha256-Mf0nrgMk1MlZkSyUN6mlM5lmTcrOHn3xBNzmVGtApEU=";

  nativeBuildInputs = [
    git
    installShellFiles
    makeWrapper
  ];

  # Don't build/fetch grammars in the build sandbox
  HELIX_DISABLE_AUTO_GRAMMAR_BUILD = "1";

  # Set runtime path
  HELIX_DEFAULT_RUNTIME = placeholder "out/lib/runtime";

  # Build the terminal version
  buildAndTestSubdir = "helix-term";

  postInstall = ''
    # Install runtime files
    mkdir -p $out/lib
    cp -r runtime $out/lib/runtime

    # Install shell completions if they exist
    if [ -d contrib/completion ]; then
      installShellCompletion --cmd hx \
        --bash contrib/completion/hx.bash \
        --fish contrib/completion/hx.fish \
        --zsh contrib/completion/hx.zsh
    fi

    # Create wrapper to set HELIX_RUNTIME if not already set
    wrapProgram $out/bin/hx \
      --set-default HELIX_RUNTIME "$out/lib/runtime"
  '';

  # Note: We skip grammar building in postFixup to avoid network access in sandbox
  # Users can run `hx --grammar fetch && hx --grammar build` after installation

  meta = with lib; {
    description = "A Helix fork with Vim-like keybindings";
    homepage = "https://github.com/badranX/vim.hx";
    license = licenses.mpl20;
    mainProgram = "hx";
    platforms = platforms.unix;
  };
}
