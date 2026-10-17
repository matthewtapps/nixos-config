{
  pkgs,
  config,
  inputs,
}:
let
  inherit (pkgs) lib;
  base16 = inputs.stylix.inputs.base16.lib { inherit pkgs lib; };
  storeId = "a7e3c9f1";
  addons = pkgs.firefox-addons;
  # Not packaged in rycee firefox-addons; bump version, url and sha256 by hand.
  no-youtube-shorts = addons.buildFirefoxXpiAddon {
    pname = "no-youtube-shorts";
    version = "3.1.4";
    addonId = "{4590d8b8-3569-46e3-a571-cabfbaeab2c1}";
    url = "https://addons.mozilla.org/firefox/downloads/file/4590220/no_youtube_shorts-3.1.4.xpi";
    sha256 = "c598c7ffe2779a1f1865d0335652f7096991fe24f3c460abf90a11e8c65ad8fd";
    meta = { };
  };
  imagus-reborn = addons.buildFirefoxXpiAddon {
    pname = "imagus-reborn";
    version = "2026.9.27";
    addonId = "{7653b5cb-d76d-442f-a98f-f3c83a118cf4}";
    url = "https://addons.mozilla.org/firefox/downloads/file/5063818/imagus_reborn-2026.9.27.xpi";
    sha256 = "a04e515b170a877ef5536715789296ff80fab0382270f82d9ddada9b9db2bb68";
    meta = { };
  };
in
{
  # One profile group for every declared profile, so Zen's switcher lists
  # them all. Home-manager's storeId alone would give each its own group.
  inherit storeId;

  avatars = {
    Personal = "star";
    Professional = "book";
    Work = "briefcase";
  };

  extensions = {
    shared = with addons; [
      ublock-origin
      darkreader
      vimium
      no-youtube-shorts
      imagus-reborn
      reddit-enhancement-suite
      add-custom-search-engine
      react-devtools
      reduxdevtools
    ];
    personal = with addons; [
      bitwarden
      leechblock-ng
      addons."7tv"
      betterttv
      toolkit-for-ynab
    ];
    work = [ addons.onepassword-password-manager ];
  };

  # Stylix's Zen CSS in another base16 scheme, marking a non-default profile.
  # It imports a Stylix-internal path, so a Stylix update can break the build.
  themed =
    scheme:
    let
      colors = base16.mkSchemeAttrs "${pkgs.base16-schemes}/share/themes/${scheme}.yaml";
      css =
        file:
        import "${inputs.stylix}/modules/zen-browser/${file}" {
          inherit colors;
          inherit (config.stylix.targets.zen-browser) opacityHex;
        };
    in
    {
      userChrome = css "userChrome.nix";
      userContent = css "userContent.nix";
      settings = {
        "zen.theme.accent-color" = "#${colors.base0D-hex}";
        "font.name.monospace.x-western" = config.stylix.fonts.monospace.name;
        "font.name.sans-serif.x-western" = config.stylix.fonts.sansSerif.name;
        "font.name.serif.x-western" = config.stylix.fonts.serif.name;
      };
    };

  mkProfile =
    {
      id,
      path,
      extensions,
    }:
    let
      readJSON = f: default: if builtins.pathExists f then builtins.fromJSON (builtins.readFile f) else default;
      data = readJSON (./profiles + "/${path}.json") { };
      byId = list: builtins.listToAttrs (map (x: { name = x.id; value = x; }) list);
      ownToolbar = ./. + "/toolbar-${path}.json";
      toolbar = if builtins.pathExists ownToolbar then ownToolbar else ./toolbar.json;
      jsonSettings =
        readJSON ./settings/shared.json { } // readJSON (./settings + "/${path}.json") { };
    in
    {
      inherit id path;
      extensions.packages = extensions;
      search = {
        force = true;
        default = "google";
        engines = {
          subreddit = {
            name = "Subreddit";
            urls = [ { template = "https://old.reddit.com/r/{searchTerms}"; } ];
            definedAliases = [ "r" ];
          };
          reddit-user = {
            name = "Reddit user";
            urls = [ { template = "https://old.reddit.com/u/{searchTerms}"; } ];
            definedAliases = [ "u" ];
          };
        };
      };
      presets.betterfox.enable = true;
      spaces = byId (data.spaces or [ ]);
      pins = byId (data.pins or [ ]);
      # Zen hides an outline on the page container; the box-shadow survives.
      userChrome =
        let
          inherit (config.lib.stylix) colors;
          private = "color-mix(in srgb, #${colors.base0B} 60%, #${colors.base00})";
        in
        ''
          :root[privatebrowsingmode]:not([inDOMFullscreen="true"]) {
            & #tabbrowser-tabbox #tabbrowser-tabpanels .browserSidebarContainer {
              box-shadow: 0 0 0 1px ${private} !important;
            }
            & #zen-appcontent-navbar-container,
            &[zen-compact-mode="true"]:not([zen-single-toolbar="true"]) #nav-bar,
            &[zen-single-toolbar="true"] #urlbar-background {
              background-image: linear-gradient(color-mix(in srgb, ${private} 15%, transparent), transparent) !important;
            }
          }
        '';
      keyboardShortcuts =
        readJSON ./shortcuts/shared.json [ ] ++ readJSON (./shortcuts + "/${path}.json") [ ];
      mods = [
        "a6335949-4465-4b71-926c-4a52d34bc9c0" # Better Find Bar
        "c6813222-6571-4ba6-8faf-58f3343324f6" # Disable Rounded Corners
      ];
      settings = {
        # Profile-scoped extensions start disabled without this.
        "extensions.autoDisableScopes" = 0;
        # user.js re-applies this on every start; toolbar edits in Zen are lost.
        "browser.uiCustomization.state" = builtins.toJSON (builtins.fromJSON (builtins.readFile toolbar));
        "browser.profiles.enabled" = true;
        "browser.profiles.created" = true;
        "toolkit.profiles.storeID" = storeId;
        "browser.download.dir" = "${config.home.homeDirectory}/downloads";
        "zen.theme.accent-color" = lib.mkDefault "#a0d490";
      }
      // lib.optionalAttrs (data ? bookmarks) {
        # Zen re-imports declared bookmarks on each start; Sync would push
        # that reset to every other device.
        "services.sync.engine.bookmarks" = false;
      }
      # zen-reconcile writes these; 90 beats Stylix and Betterfox definitions.
      // lib.mapAttrs (_: lib.mkOverride 90) jsonSettings;
    }
    // lib.optionalAttrs (data ? bookmarks) {
      bookmarks = {
        force = true;
        settings = data.bookmarks;
      };
    };
}
