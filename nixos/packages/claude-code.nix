# Wrap the nixpkgs claude-code so `node` is on PATH when claude runs.
#
# Claude Code spawns hooks (and node-based plugins) as child processes, which
# inherit claude's PATH. Adding nodejs to the wrapper's PATH prefix makes node
# available to those hooks without exposing it on the global system PATH.
#
# The upstream package wraps `claude` with makeBinaryWrapper in its installPhase;
# we re-wrap in postInstall (before autoPatchelf in fixup) to add nodejs.
{
  claude-code,
  nodejs,
  makeBinaryWrapper,
  lib,
}:
claude-code.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ makeBinaryWrapper ];
  postInstall = (old.postInstall or "") + ''
    wrapProgram $out/bin/claude \
      --prefix PATH : ${lib.makeBinPath [ nodejs ]}
  '';
})
