# Declarative Claude Code setup.
#
# Encodes the local ~/.claude state into Nix:
#   - the wrapped claude binary (node on PATH) and the claude-powerline renderer
#   - settings.json (model, statusline, enabled plugins, marketplaces)
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
  ...
}:
let
  claude-code = pkgs.callPackage ../../nixos/packages/claude-code.nix { };
  claude-powerline = pkgs.callPackage ../../nixos/packages/claude-powerline.nix { };

  cclaude = pkgs.writeShellScriptBin "cclaude" ''
    export CLAUDE_CONFIG_DIR="${home}/.claude-alt"
    exec ${claude-code}/bin/claude "$@"
  '';

  home = config.home.homeDirectory;
  pluginsDir = "${home}/.claude/plugins";

  # Full-telemetry OTel env for ahvi: logs + traces + prompts + tool content,
  # no raw API bodies. http/json because ahvi parses JSON not protobuf; metrics
  # off because ahvi has no /v1/metrics route. Endpoint is per-profile.
  mkEnv = endpoint: {
    CLAUDE_CODE_ENABLE_TELEMETRY = "1";
    CLAUDE_CODE_ENHANCED_TELEMETRY_BETA = "1";
    OTEL_LOGS_EXPORTER = "otlp";
    OTEL_TRACES_EXPORTER = "otlp";
    OTEL_METRICS_EXPORTER = "none";
    OTEL_EXPORTER_OTLP_PROTOCOL = "http/json";
    OTEL_EXPORTER_OTLP_ENDPOINT = endpoint;
    OTEL_LOG_TOOL_DETAILS = "1";
    OTEL_LOG_TOOL_CONTENT = "1";
    OTEL_LOG_USER_PROMPTS = "1";
    OTEL_LOG_RAW_API_BODIES = "0";
    OTEL_LOGS_EXPORT_INTERVAL = "2000";
  };

  # Statusline wrapper: tee the hook payload to ahvi as an ahvi.quota_sample OTel
  # log (best-effort, bounded — never stalls or breaks the statusline), then run
  # the real claude-powerline with the config in this profile's dir.
  mkStatusline =
    { endpoint, dir }:
    pkgs.writeShellScript "ahvi-statusline" ''
      input="$(cat)"
      ts="$(${pkgs.coreutils}/bin/date +%s%N)"
      ${pkgs.jq}/bin/jq -cn --arg hd "$input" --arg ts "$ts" \
        '{resourceLogs:[{scopeLogs:[{logRecords:[{timeUnixNano:$ts,body:{stringValue:"ahvi.quota_sample"},attributes:[{key:"ahvi.hookdata",value:{stringValue:$hd}}]}]}]}]}' \
        | ${pkgs.curl}/bin/curl -s -m 1 -XPOST "${endpoint}/v1/logs" -H 'content-type: application/json' --data-binary @- >/dev/null 2>&1 || true
      exec ${claude-powerline}/bin/claude-powerline --config ${dir}/claude-powerline.json <<<"$input"
    '';

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

  mkSettings =
    { endpoint, dir }:
    {
      model = "opus";
      tui = "fullscreen";
      permissions = {
        defaultMode = "auto";
      };
      env = mkEnv endpoint;
      statusLine = {
        type = "command";
        command = "${mkStatusline { inherit endpoint dir; }}";
      };
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

  # Default ~/.claude (plain `claude`) holds the WORK account login -> ahvi :8421
  # (standard ahvi ports).
  workDir = "${home}/.claude";
  # ~/.claude-alt (via cclaude wrapper) holds the PERSONAL account login -> ahvi
  # :8431 (nonstandard ports).
  personalDir = "${home}/.claude-alt";

  settingsPersonalJson = pkgs.writeText "claude-settings-personal.json" (
    builtins.toJSON (mkSettings {
      endpoint = "http://192.168.0.170:8431";
      dir = personalDir;
    })
  );
  settingsWorkJson = pkgs.writeText "claude-settings-work.json" (
    builtins.toJSON (mkSettings {
      endpoint = "http://192.168.0.170:8421";
      dir = workDir;
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
    claude-code
    claude-powerline
    cclaude
  ];

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
    $DRY_RUN_CMD ${install} -m644 ${settingsWorkJson} "$root/settings.json"
    $DRY_RUN_CMD ${install} -m644 ${./claude-powerline.json} "$root/claude-powerline.json"

    # Personal profile dir (~/.claude-alt, via cclaude): own settings + powerline,
    # plugins symlinked to the shared tree (installPaths in
    # installed_plugins.json are absolute).
    alt="${home}/.claude-alt"
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$alt"
    $DRY_RUN_CMD rm -rf "$alt/plugins"
    $DRY_RUN_CMD ln -sfn "$root/plugins" "$alt/plugins"
    $DRY_RUN_CMD ${install} -m644 ${settingsPersonalJson} "$alt/settings.json"
    $DRY_RUN_CMD ${install} -m644 ${./claude-powerline.json} "$alt/claude-powerline.json"
  '';
}
