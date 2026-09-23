# Declarative Claude Code setup.
#
# Encodes the local ~/.claude state into Nix:
#   - the wrapped claude binary (node + python3 on PATH, ahvi MCP via
#     --mcp-config) and the claude-powerline renderer
#   - settings.json (model, statusline, hooks, env, enabled plugins, marketplaces)
#   - claude-powerline.json (statusline theme)
#   - CLAUDE.md (user-level memory, from ./claude-user-memory.md)
#   - standards/{slop-rules,comment-rules}.md (the shared authoring standards
#     CLAUDE.md imports)
#   - Herdr's Claude Code integration (hooks/herdr-agent-state.sh + its
#     settings.json entry), which the Herdr installer cannot own because
#     settings.json is rewritten on every switch
#   - the plugin tree under ~/.claude/plugins
#
# Claude Code normally clones plugin/marketplace repos at runtime. This config
# pins them (reproducible, offline) and an activation script materialises them
# into ~/.claude. The plugin caches and the JSON state files are written as
# writable copies because Claude writes runtime markers (e.g. .in_use/) into the
# cache dirs and rewrites settings.json itself; a symlink into the store would
# break those writes and then clobber on the next home-manager switch.
#
# The slop-cop plugin carries the settings asserted below, the AGSM output style
# and the review/ticket skills. It sits in a private GitLab, so only a work host
# manages it; every other host takes the standards and the AGSM style from the
# copies vendored beside this file. Hence the 2 sources for one standard: a
# personal host cannot read the plugin, and slop-cop compares its installed copy
# byte-for-byte against the plugin's, so a work host must install that copy.
#
# Enforcement is overwrite-on-switch: Nix is the source of truth, so the managed
# plugin set and these files are re-asserted on every switch and any in-app drift
# is reset. typescript-lsp / the GCS-distributed claude-plugins-official
# marketplace are intentionally not managed here.
{
  config,
  pkgs,
  lib,
  host,
  inputs,
  ...
}:
let
  # ahvi MCP endpoints + launcher wrappers, shared with flake.nix's `packages`
  # output (so the ~/cs work devshell can wrap the same ahvi-aware binary).
  ahvi = import ../../nixos/packages/claude-ahvi.nix { inherit pkgs; };
  claude-code = ahvi.claude-code;
  claude-powerline = pkgs.callPackage ../../nixos/packages/claude-powerline.nix { };

  # Personal harness on work machines: own config dir + personal-server MCP.
  cclaude = ahvi.mkWrapper {
    name = "cclaude";
    apiUrl = personalEndpoints.api;
    configSubdir = ".claude-alt";
  };

  # Default `claude`: wrap the real binary to load the ahvi feedback MCP server
  # declaratively. Endpoint follows the default profile.
  claudeWrapped = ahvi.mkWrapper {
    name = "claude";
    apiUrl = defaultEndpoints.api;
  };

  home = config.home.homeDirectory;
  pluginsDir = "${home}/.claude/plugins";

  herdrClaudeHook = pkgs.callPackage ../../nixos/packages/herdr-claude-hook.nix {
    herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  # The hook script exits silently unless python3 is on PATH; prefix it here,
  # because patching the script breaks the content check Herdr runs against it.
  mkHerdrHook = dir: {
    matcher = "*";
    hooks = [
      {
        type = "command";
        timeout = 10;
        command = "PATH=${pkgs.python3}/bin:$PATH ${pkgs.bash}/bin/bash '${dir}/hooks/herdr-agent-state.sh' session";
      }
    ];
  };

  # Work machines (samar, tehol, the ones importing common-work.nix) run both
  # harnesses: `claude` (work account) + `cclaude` (personal account). Every
  # other machine runs a single personal `claude` harness only.
  isWorkMachine = builtins.elem host.name [ "samar" "tehol" ];

  # ahvi runs on samar. Work machines reach it over the WireGuard VPN address so
  # telemetry still flows when the machine travels off the home LAN; personal
  # machines reach it over the home wifi LAN.
  ahviHost = if isWorkMachine then "10.88.88.131" else "192.168.0.170";

  # ahvi exposes two ports per instance: an OTLP/HTTP ingest port (telemetry in)
  # and a query-API port (the should_sample veto + the MCP feedback server). The
  # feedback hooks + statusline + inventory tee to OTLP; the Stop nudge veto and
  # the MCP elicitation server live on the API port. Port constants + the ahvi
  # MCP wiring live in nixos/packages/claude-ahvi.nix (shared with flake.nix).
  endpoints = ahvi.mkEndpoints ahviHost;
  workEndpoints = endpoints.work;
  personalEndpoints = endpoints.personal;

  # Path to the ahvi binary that backs the statusline + the six hooks (inventory /
  # churn / feedback-start / feedback-nudge / feedback-mark / feedback-capture).
  # Not built by this config; built out of the ahvi dev project (`just dist`) to
  # this fixed dist path; just rebuild there to update. ~/dev/ahvi is a bare-repo
  # worktree layout, so the primary worktree (and its dist/) sits under main/.
  # Absolute so the hooks resolve it regardless of the inherited PATH.
  ahviBin = "${home}/dev/ahvi/main/dist/ahvi";

  # Full-telemetry OTel env for ahvi: logs + traces + prompts + tool content +
  # raw API bodies. http/json because ahvi parses JSON not protobuf; metrics
  # off because ahvi has no /v1/metrics route. Endpoints are per-profile.
  #
  # The OTEL_* vars steer the Claude Code exporter (telemetry out). The AHVI_*
  # vars steer the ahvi-server hooks: AHVI_OTLP_ENDPOINT is where inventory +
  # statusline + feedback events POST, AHVI_API_ENDPOINT is where the Stop nudge
  # asks should_sample. Both default to localhost in the binary, so they must be
  # set here for the remote (samar) instance.
  # CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC is a slop-cop blanket setting. It
  # gates Anthropic's managed metrics reader, leaving the OTLP export to ahvi
  # alone; that path keys off CLAUDE_CODE_ENABLE_TELEMETRY.
  mkEnv = endpoints: {
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
    CLAUDE_CODE_ENABLE_TELEMETRY = "1";
    CLAUDE_CODE_ENHANCED_TELEMETRY_BETA = "1";
    OTEL_LOGS_EXPORTER = "otlp";
    OTEL_TRACES_EXPORTER = "otlp";
    OTEL_METRICS_EXPORTER = "none";
    OTEL_EXPORTER_OTLP_PROTOCOL = "http/json";
    OTEL_EXPORTER_OTLP_ENDPOINT = endpoints.otlp;
    OTEL_LOG_TOOL_DETAILS = "1";
    OTEL_LOG_TOOL_CONTENT = "1";
    OTEL_LOG_USER_PROMPTS = "1";
    OTEL_LOG_RAW_API_BODIES = "1";
    OTEL_LOGS_EXPORT_INTERVAL = "2000";
    AHVI_OTLP_ENDPOINT = endpoints.otlp;
    AHVI_API_ENDPOINT = endpoints.api;
    # ahvi-native redaction knob read by `ahvi statusline`: "1" strips
    # `session_name` from hookData before POST. Off = session titles captured.
    AHVI_REDACT_SESSION_NAME = "0";
  };

  # statusLine: `ahvi-server statusline` tees the hook payload to ahvi as an
  # ahvi.quota_sample OTel log (best-effort, bounded, never stalls or breaks the
  # statusline; endpoint from AHVI_OTLP_ENDPOINT), then execs the real
  # claude-powerline renderer after the `--`.
  mkStatuslineCmd =
    dir:
    "${ahviBin} statusline -- ${claude-powerline}/bin/claude-powerline --config ${dir}/claude-powerline.json";

  # Only a work host forces this fetch, so a personal host needs neither the
  # GitLab route nor the work SSH identity to evaluate.
  slopCopRev = "70793b384ebccd56d9502f995b361a90fb8a21ad";
  slopCop = builtins.fetchGit {
    url = "git+ssh://git@gitlab.countersight.co/devops/slop-cop.git";
    ref = "group/88-0.4.0";
    rev = slopCopRev;
    # Without it, the fetch is impure and `nix flake check` refuses it.
    narHash = "sha256-veszipnwQwFhmr5JM7NK8baadECVL8BQskIeYBYlR3Y=";
  };

  # Pinned marketplace repos (full repo content, cloned into plugins/marketplaces).
  # `source` mirrors what `claude plugin marketplace add` records for that source
  # kind, so a github marketplace takes owner/repo and a git one takes the URL.
  marketplaces = {
    claude-powerline = {
      src = pkgs.fetchFromGitHub {
        owner = "Owloops";
        repo = "claude-powerline";
        rev = "28deff67a4f380ddb1d4590caa24b854c4f7c5dd";
        sha256 = "sha256-8c68N6Ty/7E6Vt35EBH0IbtEn9rQ2bxtTrKwZqHHmjs=";
      };
      source = {
        source = "github";
        repo = "Owloops/claude-powerline";
      };
    };
    # obra/superpowers is its own marketplace, named superpowers-dev.
    superpowers-dev = {
      src = pkgs.fetchFromGitHub {
        owner = "obra";
        repo = "superpowers";
        rev = "5bf4e78011075bcfc0dc295f0724994cd123ee71";
        sha256 = "08qk0qwwk5w0hwfdjg0gcad6ddl569l4d1awhqjic01j6j38j1xf";
      };
      source = {
        source = "github";
        repo = "obra/superpowers";
      };
    };
    ponytail = {
      src = pkgs.fetchFromGitHub {
        owner = "DietrichGebert";
        repo = "ponytail";
        rev = "e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156";
        sha256 = "01386kw1kg1wpgjmyzc9154b8v4hf8s10iv5bm0lbiwqnigbji1w";
      };
      source = {
        source = "github";
        repo = "DietrichGebert/ponytail";
      };
    };
  }
  // lib.optionalAttrs isWorkMachine {
    slop-cop = {
      src = slopCop;
      source = {
        source = "git";
        url = "https://gitlab.countersight.co/devops/slop-cop.git";
      };
    };
  };

  # Skill dirs this config or a pre-0.4.0 slop-cop used to install. Claude Code
  # loads every dir it finds, so one left behind competes with its plugin copy.
  staleSkills = [
    "ask-matt"
    "code-review"
    "codebase-design"
    "diagnosing-bugs"
    "domain-modeling"
    "edit-article"
    "grill-me"
    "grill-with-docs"
    "grilling"
    "handoff"
    "implement"
    "improve-codebase-architecture"
    "ponytail"
    "prototype"
    "research"
    "resolving-merge-conflicts"
    "review-code-comments"
    "review-documentation"
    "review-merge-request"
    "setup-matt-pocock-skills"
    "tdd"
    "teach"
    "to-spec"
    "to-tickets"
    "triage"
    "wayfinder"
    "writing-great-skills"
  ];

  # git guardrails: a PreToolUse(Bash) hook that blocks destructive git before it
  # runs (exit 2 => Claude sees the stderr and is refused). Ported from Matt
  # Pocock's misc/git-guardrails-claude-code skill; here it's a nix-built script
  # wired into settings.json (the skill installer would edit settings.json,
  # which this config owns and overwrites on switch).
  blockDangerousGit = pkgs.writeShellApplication {
    name = "block-dangerous-git";
    runtimeInputs = [ pkgs.jq pkgs.gnugrep ];
    text = ''
      INPUT=$(cat)
      COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

      DANGEROUS_PATTERNS=(
        "git push"
        "git reset --hard"
        "git clean -fd"
        "git clean -f"
        "git branch -D"
        "git checkout \."
        "git restore \."
        "push --force"
        "reset --hard"
      )

      for pattern in "''${DANGEROUS_PATTERNS[@]}"; do
        if echo "$COMMAND" | grep -qE "$pattern"; then
          echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
          exit 2
        fi
      done

      exit 0
    '';
  };

  # Infra guardrails: tofu/terraform writes are the user's to run, never
  # Claude's. Matches the verb anywhere in the command, so `cd tf && tofu apply`
  # and `tofu -chdir=tf apply` are caught too.
  blockInfraWrites = pkgs.writeShellApplication {
    name = "block-infra-writes";
    runtimeInputs = [
      pkgs.jq
      pkgs.gnugrep
    ];
    text = ''
      INPUT=$(cat)
      COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

      WRITES='\b(apply|destroy)\b|\bstate[[:space:]]+(rm|mv|push|replace-provider)\b'

      if echo "$COMMAND" | grep -qE "\b(tofu|terraform)\b.*($WRITES)"; then
        echo "BLOCKED: '$COMMAND' writes infrastructure. The user runs applies themselves; plan, validate and fmt are fine." >&2
        exit 2
      fi

      exit 0
    '';
  };

  ts = "2026-06-15T00:00:00.000Z";

  # cache/<marketplace>/<plugin>/<version> -> plugin content, taken from the
  # `source` each marketplace.json declares for the plugin:
  #   claude-powerline source "./plugin"  -> the repo's plugin/ subdir
  #   every other one declares "./"       -> the whole repo
  # `version` and `sha` must match the plugin.json version and the pinned rev, or
  # Claude Code re-clones the plugin over the materialised cache.
  pluginCaches = [
    {
      mp = "claude-powerline";
      plugin = "claude-powerline";
      version = "1.0.0";
      sha = "28deff67a4f380ddb1d4590caa24b854c4f7c5dd";
      src = "${marketplaces.claude-powerline.src}/plugin";
    }
    {
      mp = "superpowers-dev";
      plugin = "superpowers";
      version = "6.4.1";
      sha = "5bf4e78011075bcfc0dc295f0724994cd123ee71";
      src = "${marketplaces.superpowers-dev.src}";
    }
    {
      mp = "ponytail";
      plugin = "ponytail";
      version = "4.10.0";
      sha = "e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156";
      src = "${marketplaces.ponytail.src}";
    }
  ]
  ++ lib.optional isWorkMachine {
    mp = "slop-cop";
    plugin = "slop-cop";
    version = "0.4.0";
    sha = slopCopRev;
    src = "${slopCop}";
  };

  knownMarketplaces = lib.mapAttrs (name: m: {
    inherit (m) source;
    installLocation = "${pluginsDir}/marketplaces/${name}";
    lastUpdated = ts;
  }) marketplaces;

  installedPlugins = {
    version = 2;
    plugins = builtins.listToAttrs (
      map (p: {
        name = "${p.plugin}@${p.mp}";
        value = [
          {
            scope = "user";
            installPath = "${pluginsDir}/cache/${p.mp}/${p.plugin}/${p.version}";
            version = p.version;
            installedAt = ts;
            lastUpdated = ts;
            gitCommitSha = p.sha;
          }
        ];
      }) pluginCaches
    );
  };

  # The six ahvi hooks, all backed by ahviBin. SessionStart runs three separate
  # groups (matching `ahvi install`): `inventory` posts a harness snapshot,
  # `churn` posts default-branch commit churn for the repo, and `feedback-start`
  # records session start + arms the post-clear feedback window. The trio
  # Stop/SessionEnd/ElicitationResult drive session-feedback collection
  # (nudge -> mark carry-over -> capture the elicitation result).
  ahviHooks = {
    SessionStart = [
      { hooks = [ { type = "command"; command = "${ahviBin} inventory"; } ]; }
      { hooks = [ { type = "command"; command = "${ahviBin} churn"; } ]; }
    ];
  };

  mkSettings =
    { endpoints, dir }:
    {
      model = "opus";
      tui = "fullscreen";
      # Both are in-app-togglable (/vim, /verbose) but this file is rewritten on
      # every switch, so anything set in the UI is lost. Pin them here instead.
      verbose = false;
      editorMode = "normal"; # i.e. vim mode off
      # slop-cop's 5 blanket settings, alongside
      # CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC in mkEnv. Dropping any of them
      # makes a bare `slop-cop` report drift and exit non-zero.
      # Claude Code namespaces a plugin output style as <plugin>:<name>, so a work
      # host names the plugin's copy. Elsewhere "AGSM" is the `name:` field of
      # ./claude-agsm-style.md, installed below as output-styles/agsm.md.
      outputStyle = if isWorkMachine then "slop-cop:AGSM" else "AGSM";
      disableArtifact = true;
      includeCoAuthoredBy = false;
      permissions = {
        defaultMode = "auto";
      };
      env = mkEnv endpoints;
      statusLine = {
        type = "command";
        command = mkStatuslineCmd dir;
      };
      # ahvi telemetry/feedback hooks + Herdr's agent-state reporter + the git
      # and infra guardrails PreToolUse blocks.
      hooks = ahviHooks // {
        SessionStart = ahviHooks.SessionStart ++ [ (mkHerdrHook dir) ];
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "${blockDangerousGit}/bin/block-dangerous-git";
              }
              {
                type = "command";
                command = "${blockInfraWrites}/bin/block-infra-writes";
              }
            ];
          }
        ];
      };
      # NB: the ahvi MCP server is not declared here; Claude Code ignores
      # `mcpServers` in settings.json. It's loaded via `--mcp-config` in the
      # launcher wrappers (see nixos/packages/claude-ahvi.nix).
      enabledPlugins = builtins.listToAttrs (
        map (p: {
          name = "${p.plugin}@${p.mp}";
          value = true;
        }) pluginCaches
      );
      extraKnownMarketplaces = lib.mapAttrs (_: m: { inherit (m) source; }) marketplaces;
      skipAutoPermissionPrompt = true;
    };

  # Default ~/.claude (plain `claude`):
  #   - work machines    -> WORK account     -> work server (otlp 8421 / api 8420)
  #   - personal machines -> PERSONAL account -> personal server (otlp 8431 / api 8430)
  defaultEndpoints = if isWorkMachine then workEndpoints else personalEndpoints;
  defaultSettingsJson = pkgs.writeText "claude-settings.json" (
    builtins.toJSON (mkSettings {
      endpoints = defaultEndpoints;
      dir = "${home}/.claude";
    })
  );
  # Work machines only: ~/.claude-alt (via the cclaude wrapper) holds the PERSONAL
  # account login -> personal server (otlp 8431 / api 8430).
  altSettingsJson = pkgs.writeText "claude-settings-alt.json" (
    builtins.toJSON (mkSettings {
      endpoints = personalEndpoints;
      dir = "${home}/.claude-alt";
    })
  );
  # A work host installs the plugin's own copies, because slop-cop reports drift
  # when the installed standard differs from the one the plugin ships.
  standards =
    if isWorkMachine then
      {
        slop = "${slopCop}/standards/slop-rules.md";
        comment = "${slopCop}/standards/comment-rules.md";
      }
    else
      {
        slop = ./claude-slop-rules.md;
        comment = ./claude-comment-rules.md;
      };

  installedPluginsJson = pkgs.writeText "installed_plugins.json" (builtins.toJSON installedPlugins);
  knownMarketplacesJson = pkgs.writeText "known_marketplaces.json" (builtins.toJSON knownMarketplaces);

  cp = "${pkgs.coreutils}/bin/cp";
  install = "${pkgs.coreutils}/bin/install";

  marketplaceCmds = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: m: ''install_tree ${m.src} "$root/plugins/marketplaces/${name}"''
    ) marketplaces
  );

  cacheCmds = lib.concatStringsSep "\n" (
    map (
      p: ''install_tree ${p.src} "$root/plugins/cache/${p.mp}/${p.plugin}/${p.version}"''
    ) pluginCaches
  );

  # Each removal names one directory, so a skill you install by hand survives a
  # switch.
  staleSkillCmds = lib.concatStringsSep "\n" (
    map (name: ''$DRY_RUN_CMD rm -rf $VERBOSE_ARG "$root/skills/${name}"'') staleSkills
  );
in
{
  home.packages = [
    claudeWrapped # `claude` wrapper (adds --mcp-config); pulls in claude-code
    claude-powerline
    pkgs.ast-grep # the ast-grep skill invokes this by bare name
  ]
  # cclaude (the personal work-machine harness) only exists on work machines.
  ++ lib.optional isWorkMachine cclaude;

  home.activation.claudeCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    root="${home}/.claude"
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$root/plugins/marketplaces" "$root/plugins/cache" "$root/skills"

    install_tree() {
      src="$1"; dest="$2"
      $DRY_RUN_CMD rm -rf "$dest"
      $DRY_RUN_CMD mkdir -p "$(dirname "$dest")"
      # Preserve source modes (some plugin hooks ship +x and Claude invokes them
      # directly) but not ownership. Then add u+w so Claude can write runtime
      # markers into the otherwise read-only store-derived tree.
      $DRY_RUN_CMD ${cp} -rT --no-preserve=ownership "$src" "$dest"
      $DRY_RUN_CMD chmod -R u+w "$dest"
    }

    ${marketplaceCmds}
    ${cacheCmds}
    ${staleSkillCmds}

    $DRY_RUN_CMD ${install} -m644 ${installedPluginsJson} "$root/plugins/installed_plugins.json"
    $DRY_RUN_CMD ${install} -m644 ${knownMarketplacesJson} "$root/plugins/known_marketplaces.json"
    $DRY_RUN_CMD ${install} -m644 ${defaultSettingsJson} "$root/settings.json"
    $DRY_RUN_CMD ${install} -m644 ${./claude-powerline.json} "$root/claude-powerline.json"
    $DRY_RUN_CMD ${install} -m644 ${./claude-user-memory.md} "$root/CLAUDE.md"
    # slop-cop blanket assets; dropping either makes a bare `slop-cop` report
    # drift. Both are imported by absolute ~/.claude path, so this one copy also
    # serves ~/.claude-alt.
    $DRY_RUN_CMD ${install} -Dm644 ${standards.slop} "$root/standards/slop-rules.md"
    $DRY_RUN_CMD ${install} -Dm644 ${standards.comment} "$root/standards/comment-rules.md"
    $DRY_RUN_CMD ${install} -Dm755 ${herdrClaudeHook} "$root/hooks/herdr-agent-state.sh"
    ${
      if isWorkMachine then
        ''
          # The plugin carries the style a work host names, and slop-cop reports a
          # copy here as a leftover of the version that installed one.
          $DRY_RUN_CMD rm -f $VERBOSE_ARG "$root/output-styles/agsm.md"''
      else
        ''$DRY_RUN_CMD ${install} -Dm644 ${./claude-agsm-style.md} "$root/output-styles/agsm.md"''
    }
    ${lib.optionalString isWorkMachine ''

      # Work machines only: second ~/.claude-alt profile (personal account via the
      # cclaude wrapper). Own settings + powerline; plugins symlinked to the shared
      # tree (installPaths in installed_plugins.json are absolute).
      alt="${home}/.claude-alt"
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$alt"
      $DRY_RUN_CMD rm -rf "$alt/plugins"
      $DRY_RUN_CMD ln -sfn "$root/plugins" "$alt/plugins"
      # Share the skills dir with the personal profile too.
      $DRY_RUN_CMD rm -rf "$alt/skills"
      $DRY_RUN_CMD ln -sfn "$root/skills" "$alt/skills"
      $DRY_RUN_CMD ${install} -m644 ${altSettingsJson} "$alt/settings.json"
      $DRY_RUN_CMD ${install} -m644 ${./claude-powerline.json} "$alt/claude-powerline.json"
      $DRY_RUN_CMD ${install} -m644 ${./claude-user-memory.md} "$alt/CLAUDE.md"
      $DRY_RUN_CMD rm -f $VERBOSE_ARG "$alt/output-styles/agsm.md"
      $DRY_RUN_CMD ${install} -Dm755 ${herdrClaudeHook} "$alt/hooks/herdr-agent-state.sh"
    ''}
  '';
}
