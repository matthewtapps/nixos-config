# Declarative Claude Code setup.
#
# Encodes the local ~/.claude state into Nix:
#   - the wrapped claude binary (node on PATH, ahvi MCP via --mcp-config) and the
#     claude-powerline renderer
#   - settings.json (model, statusline, hooks, env, enabled plugins, marketplaces)
#   - claude-powerline.json (statusline theme)
#   - the plugin tree under ~/.claude/plugins
#
# Claude Code normally clones plugin/marketplace repos from GitHub at runtime.
# Instead we pin them with fetchFromGitHub (reproducible, offline) and an
# activation script materialises them into ~/.claude. The plugin caches and the
# JSON state files are written as *writable copies* (not read-only store
# symlinks) because Claude writes runtime markers (e.g. .in_use/) into the cache
# dirs and rewrites settings.json on its own; a symlink into the store would
# break those writes and then clobber on the next home-manager switch.
#
# Enforcement is overwrite-on-switch: Nix is the source of truth, so the managed
# plugin set and these files are re-asserted on every switch and any in-app drift
# is reset. typescript-lsp / the GCS-distributed claude-plugins-official
# marketplace are intentionally NOT managed here.
{
  config,
  pkgs,
  lib,
  host,
  ...
}:
let
  claude-code = pkgs.callPackage ../../nixos/packages/claude-code.nix { };
  claude-powerline = pkgs.callPackage ../../nixos/packages/claude-powerline.nix { };

  # Personal harness on work machines: own config dir + personal-server MCP.
  cclaude = pkgs.writeShellScriptBin "cclaude" ''
    export CLAUDE_CONFIG_DIR="${home}/.claude-alt"
    exec ${claude-code}/bin/claude --mcp-config ${personalMcpJson} "$@"
  '';

  # Default `claude`: wrap the real binary to load the ahvi feedback MCP server
  # declaratively (see mkMcpJson). Endpoint follows the default profile.
  claudeWrapped = pkgs.writeShellScriptBin "claude" ''
    exec ${claude-code}/bin/claude --mcp-config ${defaultMcpJson} "$@"
  '';

  home = config.home.homeDirectory;
  pluginsDir = "${home}/.claude/plugins";

  # Work machines (samar, tehol — the ones importing common-work.nix) run BOTH
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
  # the MCP elicitation server live on the API port.
  #   work server:     otlp 8421, api 8420
  #   personal server: otlp 8431, api 8430
  mkEndpoints = { otlpPort, apiPort }: {
    otlp = "http://${ahviHost}:${toString otlpPort}";
    api = "http://${ahviHost}:${toString apiPort}";
  };
  workEndpoints = mkEndpoints {
    otlpPort = 8421;
    apiPort = 8420;
  };
  personalEndpoints = mkEndpoints {
    otlpPort = 8431;
    apiPort = 8430;
  };

  # ahvi feedback MCP server. Claude Code does NOT read `mcpServers` from
  # settings.json — it loads MCP servers from ~/.claude.json (volatile, rewritten
  # by Claude) or from files passed via `--mcp-config`. We use the latter so the
  # registration is declarative and non-volatile; the launcher wrappers above
  # pass the per-profile file. `--mcp-config` is additive to any user-scope
  # servers, so it won't clobber `claude mcp add` entries.
  mkMcpJson =
    endpoints:
    pkgs.writeText "ahvi-mcp.json" (
      builtins.toJSON {
        mcpServers.ahvi = {
          type = "http";
          url = "${endpoints.api}/mcp";
        };
      }
    );
  defaultMcpJson = mkMcpJson defaultEndpoints;
  personalMcpJson = mkMcpJson personalEndpoints;

  # Path to the ahvi binary that backs the statusline + the four hooks
  # (inventory / feedback-nudge / feedback-mark / feedback-capture). NOT built by
  # this config — built out of the ahvi dev project to this fixed dist path; just
  # rebuild there to update. Absolute so the hooks resolve it regardless of the
  # inherited PATH.
  ahviBin = "${home}/dev/ahvi/dist/ahvi";

  # Full-telemetry OTel env for ahvi: logs + traces + prompts + tool content +
  # raw API bodies. http/json because ahvi parses JSON not protobuf; metrics
  # off because ahvi has no /v1/metrics route. Endpoints are per-profile.
  #
  # The OTEL_* vars steer Claude Code's own exporter (telemetry out). The AHVI_*
  # vars steer the ahvi-server hooks: AHVI_OTLP_ENDPOINT is where inventory +
  # statusline + feedback events POST, AHVI_API_ENDPOINT is where the Stop nudge
  # asks should_sample. Both default to localhost in the binary, so they MUST be
  # set here for the remote (samar) instance.
  mkEnv = endpoints: {
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
  };

  # statusLine: `ahvi-server statusline` tees the hook payload to ahvi as an
  # ahvi.quota_sample OTel log (best-effort, bounded — never stalls or breaks the
  # statusline; endpoint from AHVI_OTLP_ENDPOINT), then execs the real
  # claude-powerline renderer after the `--`. Replaces the old hand-rolled
  # jq/curl tee — the binary owns that behavior now (`ahvi install` parity).
  mkStatuslineCmd =
    dir:
    "${ahviBin} statusline -- ${claude-powerline}/bin/claude-powerline --config ${dir}/claude-powerline.json";

  # Pinned marketplace repos (full repo content, cloned into plugins/marketplaces).
  mp = {
    caveman = pkgs.fetchFromGitHub {
      owner = "JuliusBrussee";
      repo = "caveman";
      rev = "655b7d9c5431f822264b7732e9901c5578ac84cf";
      sha256 = "1chxccncngr0syc39ykjlmzxgj669vnzkfa3xvijsspgvw9529q7";
    };
    claude-powerline = pkgs.fetchFromGitHub {
      owner = "Owloops";
      repo = "claude-powerline";
      rev = "28deff67a4f380ddb1d4590caa24b854c4f7c5dd";
      sha256 = "sha256-8c68N6Ty/7E6Vt35EBH0IbtEn9rQ2bxtTrKwZqHHmjs=";
    };
    superpowers-marketplace = pkgs.fetchFromGitHub {
      owner = "obra";
      repo = "superpowers-marketplace";
      rev = "af4c8d88b6d99926493709ade76f4369f9132390";
      sha256 = "0s801av9db45rbc2jxxzm4bdf5b3rwh4jfbjn57wnngaplymd44m";
    };
  };

  # superpowers' plugin source is a separate repo from its marketplace.
  superpowersPlugin = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "6fd4507659784c351abbd2bc264c7162cfd386dc";
    sha256 = "0fjbbnzsf3vk3wc64rpsqjry6sxzfvq07dy7phry8fyhfkq47w9z";
  };

  ts = "2026-06-15T00:00:00.000Z";

  # cache/<marketplace>/<plugin>/<version> -> plugin content, taken from the
  # `source` each marketplace.json declares for the plugin:
  #   caveman          source "./"        -> marketplace repo root
  #   claude-powerline source "./plugin"  -> the repo's plugin/ subdir
  #   superpowers      source url         -> its own separate repo
  pluginCaches = [
    {
      mp = "caveman";
      plugin = "caveman";
      version = "655b7d9c5431";
      sha = "655b7d9c5431f822264b7732e9901c5578ac84cf";
      src = mp.caveman;
    }
    {
      mp = "claude-powerline";
      plugin = "claude-powerline";
      version = "1.0.0";
      sha = "28deff67a4f380ddb1d4590caa24b854c4f7c5dd";
      src = "${mp.claude-powerline}/plugin";
    }
    {
      mp = "superpowers-marketplace";
      plugin = "superpowers";
      version = "5.1.0";
      sha = "6fd4507659784c351abbd2bc264c7162cfd386dc";
      src = superpowersPlugin;
    }
  ];

  marketplaceRepos = {
    caveman = "JuliusBrussee/caveman";
    claude-powerline = "Owloops/claude-powerline";
    superpowers-marketplace = "obra/superpowers-marketplace";
  };

  knownMarketplaces = lib.mapAttrs (name: repo: {
    source = {
      source = "github";
      inherit repo;
    };
    installLocation = "${pluginsDir}/marketplaces/${name}";
    lastUpdated = ts;
  }) marketplaceRepos;

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

  # The four ahvi hooks, all backed by ahviBin. SessionStart posts a harness
  # inventory; the trio Stop/SessionEnd/ElicitationResult drive session-feedback
  # collection (nudge → mark carry-over → capture the elicitation result).
  ahviHooks = {
    SessionStart = [ { hooks = [ { type = "command"; command = "${ahviBin} inventory"; } ]; } ];
    Stop = [ { hooks = [ { type = "command"; command = "${ahviBin} feedback-nudge"; } ]; } ];
    SessionEnd = [ { hooks = [ { type = "command"; command = "${ahviBin} feedback-mark"; } ]; } ];
    ElicitationResult = [ { hooks = [ { type = "command"; command = "${ahviBin} feedback-capture"; } ]; } ];
  };

  mkSettings =
    { endpoints, dir }:
    {
      model = "opus";
      tui = "fullscreen";
      permissions = {
        defaultMode = "auto";
      };
      env = mkEnv endpoints;
      statusLine = {
        type = "command";
        command = mkStatuslineCmd dir;
      };
      hooks = ahviHooks;
      # NB: the ahvi MCP server is NOT declared here — Claude Code ignores
      # `mcpServers` in settings.json. It's loaded via `--mcp-config` in the
      # launcher wrappers instead (see mkMcpJson).
      enabledPlugins = builtins.listToAttrs (
        map (p: {
          name = "${p.plugin}@${p.mp}";
          value = true;
        }) pluginCaches
      );
      extraKnownMarketplaces = lib.mapAttrs (_: repo: {
        source = {
          source = "github";
          inherit repo;
        };
      }) marketplaceRepos;
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
  installedPluginsJson = pkgs.writeText "installed_plugins.json" (builtins.toJSON installedPlugins);
  knownMarketplacesJson = pkgs.writeText "known_marketplaces.json" (builtins.toJSON knownMarketplaces);

  cp = "${pkgs.coreutils}/bin/cp";
  install = "${pkgs.coreutils}/bin/install";

  marketplaceCmds = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: src: ''install_tree ${src} "$root/plugins/marketplaces/${name}"''
    ) mp
  );

  cacheCmds = lib.concatStringsSep "\n" (
    map (
      p: ''install_tree ${p.src} "$root/plugins/cache/${p.mp}/${p.plugin}/${p.version}"''
    ) pluginCaches
  );
in
{
  home.packages = [
    claudeWrapped # `claude` wrapper (adds --mcp-config); pulls in claude-code
    claude-powerline
  ]
  # cclaude (the personal work-machine harness) only exists on work machines.
  ++ lib.optional isWorkMachine cclaude;

  home.activation.claudeCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    root="${home}/.claude"
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$root/plugins/marketplaces" "$root/plugins/cache"

    install_tree() {
      src="$1"; dest="$2"
      $DRY_RUN_CMD rm -rf "$dest"
      $DRY_RUN_CMD mkdir -p "$(dirname "$dest")"
      # Preserve source modes (some plugin hooks ship +x, e.g. superpowers'
      # run-hook.cmd which Claude invokes directly) but not ownership. Then add
      # u+w so Claude can write runtime markers into the otherwise read-only
      # store-derived tree.
      $DRY_RUN_CMD ${cp} -rT --no-preserve=ownership "$src" "$dest"
      $DRY_RUN_CMD chmod -R u+w "$dest"
    }

    ${marketplaceCmds}
    ${cacheCmds}

    $DRY_RUN_CMD ${install} -m644 ${installedPluginsJson} "$root/plugins/installed_plugins.json"
    $DRY_RUN_CMD ${install} -m644 ${knownMarketplacesJson} "$root/plugins/known_marketplaces.json"
    $DRY_RUN_CMD ${install} -m644 ${defaultSettingsJson} "$root/settings.json"
    $DRY_RUN_CMD ${install} -m644 ${./claude-powerline.json} "$root/claude-powerline.json"
    ${lib.optionalString isWorkMachine ''

      # Work machines only: second ~/.claude-alt profile (personal account via the
      # cclaude wrapper). Own settings + powerline; plugins symlinked to the shared
      # tree (installPaths in installed_plugins.json are absolute).
      alt="${home}/.claude-alt"
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$alt"
      $DRY_RUN_CMD rm -rf "$alt/plugins"
      $DRY_RUN_CMD ln -sfn "$root/plugins" "$alt/plugins"
      $DRY_RUN_CMD ${install} -m644 ${altSettingsJson} "$alt/settings.json"
      $DRY_RUN_CMD ${install} -m644 ${./claude-powerline.json} "$alt/claude-powerline.json"
    ''}
  '';
}
