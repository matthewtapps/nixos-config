# Wrap the nixpkgs claude-code so `node` and `python3` are on PATH when claude
# runs.
#
# Claude Code spawns hooks, plugin commands and skills as child processes, which
# inherit claude's PATH. node backs the node-based plugins, and python3 backs the
# slop-cop plugin's bin/slop-cop; putting both here keeps them off the global
# system PATH.
#
# The upstream package wraps `claude` with makeBinaryWrapper in its installPhase;
# we re-wrap in postInstall (before autoPatchelf in fixup) to add them.
{
  claude-code,
  nodejs,
  python3,
  makeBinaryWrapper,
  lib,
}:
claude-code.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ makeBinaryWrapper ];
  postInstall = (old.postInstall or "") + ''
    wrapProgram $out/bin/claude \
      --prefix PATH : ${
        lib.makeBinPath [
          nodejs
          python3
        ]
      }
  '';
})
