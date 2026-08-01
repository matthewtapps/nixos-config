# Herdr's Claude Code hook script, produced by running Herdr's own installer at
# build time instead of vendoring the script text: Herdr stamps
# HERDR_INTEGRATION_VERSION into it and reports stale copies as outdated. The
# settings.json half of the integration lives in home/programs/claude-code.nix.
{
  runCommand,
  herdr,
}:
runCommand "herdr-claude-hook.sh" { } ''
  export HOME="$TMPDIR/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
  ${herdr}/bin/herdr integration install claude
  install -Dm755 "$CLAUDE_CONFIG_DIR/hooks/herdr-agent-state.sh" $out
''
