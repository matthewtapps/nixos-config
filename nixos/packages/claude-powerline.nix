{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

# Renderer for the Claude Code statusline. The matching plugin in
# ~/.claude (claude-powerline@claude-powerline) is only the setup wizard;
# this is the binary the statusLine command actually invokes on every paint.
#
# Pinned to main @ 28deff6, which package.json reports as 1.27.0 (the repo
# does not push release tags). bin/claude-powerline does `import
# '../dist/index.mjs'`; dist/ is gitignored and absent from package.json's
# `files` allowlist, but buildNpmPackage's default install copies the
# post-build working tree, so dist/ is included anyway. patchShebangs
# rewrites `#!/usr/bin/env node` to this derivation's node, so the binary
# carries its own runtime and works outside any project devshell.
buildNpmPackage rec {
  pname = "claude-powerline";
  version = "1.27.0";

  src = fetchFromGitHub {
    owner = "Owloops";
    repo = "claude-powerline";
    rev = "28deff67a4f380ddb1d4590caa24b854c4f7c5dd";
    hash = "sha256-8c68N6Ty/7E6Vt35EBH0IbtEn9rQ2bxtTrKwZqHHmjs=";
  };

  npmDepsHash = "sha256-D3Z5tb4phZUMPQaXvfYiIWuwaX5YGI8ubgyV7sSJqQk=";

  meta = {
    description = "Vim-style powerline statusline for Claude Code";
    homepage = "https://github.com/Owloops/claude-powerline";
    license = lib.licenses.mit;
    mainProgram = "claude-powerline";
    platforms = lib.platforms.unix;
  };
}
