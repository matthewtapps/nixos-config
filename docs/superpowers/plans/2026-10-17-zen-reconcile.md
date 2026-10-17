# Zen reconcile tool implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** `zen-reconcile`, a Textual TUI that lists how each live Zen profile
differs from the repo, and promotes, reverts, skips or ignores each difference.

**Architecture:** `zen_profile.py` is a library that reads live profile files
and repo JSON, computes `Diff` rows and applies actions. `zen-export.py` and
`zen-reconcile.py` are thin commands over it. Settings and shortcuts move from
`lib.nix` into JSON so the tool can write them; Nix merges JSON settings with
`lib.mkOverride 90`.

**Tech Stack:** Python 3 with `lz4`, `textual` 0.81 and `pytest` 8.3; Nix,
home-manager and the zen-browser-flake module.

**Spec:** `docs/superpowers/specs/2026-10-17-zen-reconcile-design.md`

## Global constraints

- Repo JSON writes use `json.dump(..., indent=2, sort_keys=True,
  ensure_ascii=False)` plus a trailing newline.
- Before editing a Zen-owned file (`prefs.js`, `zen-sessions.jsonlz4`,
  `zen-keyboard-shortcuts.json`) copy it to `<file>.pre-reconcile`.
- Never edit a Zen-owned file while the profile's `lock` link points at a live
  PID; queue the revert instead.
- The tool never runs git, `nixswitch` or deploys.
- Comments follow `~/.claude/standards/comment-rules.md`.
- Commit messages use Conventional Commits; commit on `main`.
- Flakes only see tracked files: `git add` new files before `nix build`.

Commands used throughout:

```bash
# Python env for the tools and tests
PYENV='nix shell --impure --expr "with import <nixpkgs> {}; python3.withPackages (p: [p.lz4 p.textual p.pytest])" -c'
TESTS="$PYENV python3 -m pytest -q home/programs/zen/tests"

hmbuild() { nix build --no-link --print-out-paths ".#nixosConfigurations.$1.config.home-manager.users.matt.home.activationPackage"; }
userjs() { nix eval --raw ".#nixosConfigurations.$1.config.home-manager.users.matt.home.file" --apply "f: f.\${builtins.head (builtins.filter (n: builtins.match \".*zen/$2/user.js\" n != null) (builtins.attrNames f))}.text"; }
```

## Review focus

- A profile whose JSON has no `bookmarks` key (Work): promoting a pin must not
  start managing its bookmarks, or the next start wipes them. Task 1 makes
  bookmarks conditional on the key; Task 5 tests that a pin promote writes no
  `bookmarks` key.
- Zen running during revert: Zen rewrites its files from memory, so the edit
  would be lost. Task 5 tests that reverts are queued while `lock` points at a
  live PID.
- A promoted override of a Stylix or Betterfox setting: two plain definitions
  of one pref conflict at build. Task 1 checks `mkOverride 90` wins.
- Seeded setting ignores hiding real changes: ignores only hide undeclared
  settings, never a declared one that changed. Task 4 tests this.
- Prefs with escaped quotes or JSON strings as values (the toolbar state):
  Task 3 tests the `prefs.js` parser on both.

---

### Task 1: Move settings and shortcuts into JSON

**Files:**
- Create: `home/programs/zen/settings/shared.json`
- Create: `home/programs/zen/settings/work.json`
- Create: `home/programs/zen/settings/ignore.json`
- Create: `home/programs/zen/shortcuts/shared.json`
- Modify: `home/programs/zen/lib.nix`
- Modify: `home/programs/zen/default.nix`
- Modify: `home/programs/zen/work.nix`

**Interfaces:**
- Produces: `mkProfile { id, path, extensions }`. It reads
  `profiles/<path>.json` (when present), `settings/shared.json`,
  `settings/<path>.json`, `shortcuts/shared.json`, `shortcuts/<path>.json` and
  `toolbar-<path>.json` or `toolbar.json`. Bookmarks are declared only when the
  profile JSON has a `bookmarks` key.

- [ ] **Step 1: Snapshot the current generated config**

```bash
mkdir -p /tmp/zen-refactor
for h in karsa:personal karsa:professional tehol:personal tehol:professional tehol:work; do
  userjs ${h%%:*} ${h##*:} > /tmp/zen-refactor/$h.before
done
for h in karsa tehol; do
  nix eval --json ".#nixosConfigurations.$h.config.home-manager.users.matt.programs.zen-browser.profiles" \
    --apply 'ps: builtins.mapAttrs (_: p: { inherit (p) keyboardShortcuts; bookmarks = p.bookmarks.settings; pins = builtins.attrNames p.pins; }) ps' \
    > /tmp/zen-refactor/$h.profiles.before
done
```

- [ ] **Step 2: Write the JSON files**

`settings/shared.json`:

```json
{
  "accessibility.typeaheadfind.flashBar": 0,
  "browser.cache.disk.enable": true,
  "browser.download.folderList": 2,
  "browser.download.useDownloadDir": false,
  "browser.formfill.enable": true,
  "browser.newtabpage.enabled": false,
  "browser.search.suggest.enabled": true,
  "browser.sessionstore.interval": 15000,
  "browser.startup.homepage": "chrome://browser/content/blanktab.html",
  "browser.startup.page": 1,
  "browser.tabs.hoverPreview.showThumbnails": false,
  "browser.tabs.inTitlebar": 1,
  "browser.toolbars.bookmarks.showOtherBookmarks": false,
  "browser.toolbars.bookmarks.visibility": "newtab",
  "browser.urlbar.quicksuggest.dataCollection.enabled": false,
  "general.autoScroll": true,
  "general.smoothScroll": false,
  "layout.css.prefers-color-scheme.content-override": 0,
  "media.navigator.video.default_height": 1080,
  "media.navigator.video.default_width": 1920,
  "media.videocontrols.picture-in-picture.video-toggle.enabled": false,
  "network.trr.mode": 5,
  "permissions.default.desktop-notification": 0,
  "privacy.donottrackheader.enabled": true,
  "privacy.fingerprintingProtection": true,
  "privacy.query_stripping.enabled": true,
  "privacy.query_stripping.enabled.pbmode": true,
  "sidebar.visibility": "hide-launcher",
  "theme.better_find_bar.textbox_width": "800",
  "theme.better_find_bar.transparent_background": true,
  "toolkit.legacyUserProfileCustomizations.stylesheets": true,
  "ui.key.menuAccessKeyFocuses": false,
  "zen.glance.enabled": false,
  "zen.pinned-tab-manager.restore-pinned-tabs-to-pinned-url": true,
  "zen.site-data-panel.show-callout": false,
  "zen.tab-unloader.enabled": false,
  "zen.tabs.close-on-back-with-no-history": false,
  "zen.tabs.dim-pending": false,
  "zen.tabs.select-recently-used-on-close": false,
  "zen.theme.color-prefs.colorful": true,
  "zen.theme.color-prefs.use-workspace-colors": false,
  "zen.urlbar.behavior": "normal",
  "zen.urlbar.replace-newtab": false,
  "zen.view.compact.enable-at-startup": true,
  "zen.view.compact.should-enable-at-startup": true,
  "zen.view.show-bottom-border": true,
  "zen.view.show-newtab-button-top": false,
  "zen.view.sidebar-expanded.on-hover": false,
  "zen.view.split-view.change-on-hover": false,
  "zen.view.use-single-toolbar": false,
  "zen.view.window.scheme": 0,
  "zen.welcome-screen.seen": true
}
```

`settings/work.json`:

```json
{
  "browser.download.always_ask_before_handling_new_types": true,
  "browser.download.deletePrivate": true,
  "privacy.clearOnShutdown_v2.formdata": true
}
```

`settings/ignore.json` (prefixes end in `*`; only undeclared settings are
hidden by these):

```json
{
  "setting": [
    "app.*",
    "browser.bookmarks.editDialog.*",
    "browser.download.panel.*",
    "browser.download.viewableInternally.*",
    "browser.eme.*",
    "browser.firefox-view.*",
    "browser.ipProtection.*",
    "browser.laterrun.*",
    "browser.migration.*",
    "browser.newtabpage.*",
    "browser.pageActions.*",
    "browser.policies.*",
    "browser.region.*",
    "browser.rights.*",
    "browser.safebrowsing.*",
    "browser.search.region",
    "browser.search.serpEventTelemetryCategorization.*",
    "browser.search.totalSearches",
    "browser.shell.*",
    "browser.startup.homepage_override.*",
    "browser.startup.lastColdStartupCheck",
    "browser.termsofuse.*",
    "browser.translations.*",
    "browser.urlbar.placeholderName*",
    "browser.urlbar.quicksuggest.scenario",
    "browser.urlbar.tipShownCount.*",
    "captchadetection.*",
    "datareporting.*",
    "devtools.*",
    "distribution.*",
    "doh-rollout.*",
    "dom.push.*",
    "dom.security.https_only_mode_ever_enabled",
    "extensions.*",
    "gfx.*",
    "identity.*",
    "idle.*",
    "media.gmp*",
    "media.videocontrols.picture-in-picture.video-toggle.first-seen-secs",
    "media.videocontrols.picture-in-picture.video-toggle.has-used",
    "network.trr.blocklist*",
    "nimbus.*",
    "pdfjs.*",
    "places.*",
    "privacy.bounceTrackingProtection.*",
    "privacy.globalprivacycontrol.was_ever_enabled",
    "privacy.purge*",
    "privacy.sanitize.*",
    "privacy.trackingprotection.allow_list.*",
    "security.*",
    "services.*",
    "signon.*",
    "storage.*",
    "toolkit.*",
    "trailhead.*",
    "zen.keyboard.shortcuts.version",
    "zen.library.*",
    "zen.mods.*",
    "zen.sidebar.data",
    "zen.urlbar.suggestions-learner",
    "zen.welcomeScreen.*",
    "zen.workspaces.active"
  ]
}
```

`shortcuts/shared.json`:

```json
[
  {
    "id": "zen-compact-mode-toggle",
    "key": "c",
    "modifiers": { "accel": true, "alt": true }
  },
  {
    "id": "zen-workspace-forward",
    "key": "e",
    "keycode": "",
    "modifiers": { "accel": true, "alt": true }
  },
  {
    "id": "zen-workspace-backward",
    "key": "q",
    "keycode": "",
    "modifiers": { "accel": true, "alt": true }
  },
  {
    "id": "zen-toggle-sidebar",
    "key": "b",
    "modifiers": { "alt": true }
  },
  {
    "id": "key_savePage",
    "key": "s",
    "modifiers": { "accel": true }
  },
  { "id": "key_toggleReaderMode", "disabled": false },
  { "id": "key_exitFullScreen", "disabled": false }
]
```

- [ ] **Step 3: Rewrite `mkProfile` in `lib.nix`**

Replace the whole `mkProfile = ...;` binding (from `mkProfile =` to the closing
`};` before the final `}`) with:

```nix
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
```

- [ ] **Step 4: Drop the old arguments from the callers**

In `default.nix`, remove `file = ./profiles/personal.json;` and
`file = ./profiles/professional.json;`.

In `work.nix`, remove `toolbar = ./toolbar-work.json;` and the whole
`settings = { ... };` block from the Work attribute set (they are now
`settings/work.json` and the `toolbar-<path>.json` rule).

- [ ] **Step 5: Compare against the snapshot**

```bash
git add home/programs/zen
for h in karsa:personal karsa:professional tehol:personal tehol:professional tehol:work; do
  userjs ${h%%:*} ${h##*:} > /tmp/zen-refactor/$h.after
  diff -q /tmp/zen-refactor/$h.before /tmp/zen-refactor/$h.after && echo "$h same"
done
for h in karsa tehol; do
  nix eval --json ".#nixosConfigurations.$h.config.home-manager.users.matt.programs.zen-browser.profiles" \
    --apply 'ps: builtins.mapAttrs (_: p: { inherit (p) keyboardShortcuts; bookmarks = p.bookmarks.settings; pins = builtins.attrNames p.pins; }) ps' \
    > /tmp/zen-refactor/$h.profiles.after
  diff -q /tmp/zen-refactor/$h.profiles.before /tmp/zen-refactor/$h.profiles.after && echo "$h profiles same"
done
```

Expected: every line ends in `same`. If `keyboardShortcuts` differ only by
`null` fields now present or absent, compare with `jq -S` and accept that
difference; any value change is a bug.

- [ ] **Step 6: Check a JSON override beats Stylix**

```bash
echo '{ "font.name.serif.x-western": "Test Serif" }' > home/programs/zen/settings/personal.json
git add home/programs/zen/settings/personal.json
userjs karsa personal | grep 'font.name.serif.x-western'
git rm -q --cached home/programs/zen/settings/personal.json && rm home/programs/zen/settings/personal.json
```

Expected: `user_pref("font.name.serif.x-western", "Test Serif");` with no
evaluation error.

- [ ] **Step 7: Build and commit**

```bash
hmbuild karsa
git add home/programs/zen
git commit -m "refactor(zen): move settings and shortcuts into JSON for zen-reconcile"
```

---

### Task 2: Shortcut baseline activation step

**Files:**
- Modify: `home/programs/zen/default.nix`

**Interfaces:**
- Produces: `<profile>/zen-shortcuts-baseline.json` shaped
  `{"version": <int>, "shortcuts": [<entry>, ...]}`, written when missing or
  when `zen.keyboard.shortcuts.version` in `prefs.js` differs from `version`.

- [ ] **Step 1: Add the activation entry**

Add next to `home.activation.zen-profile-group` in `default.nix`:

```nix
  # zen-reconcile diffs live shortcuts against this. Zen's file marks no
  # user edits, so the baseline is the state right after declared ones apply.
  home.activation.zen-shortcuts-baseline = lib.hm.dag.entryAfter (map (n: "zen-browser-${n}") (
    builtins.attrNames config.programs.zen-browser.profiles
  )) (
    lib.concatMapStrings (p: ''
      dir=${lib.escapeShellArg "${config.programs.zen-browser.configPath}/${p.path}"}
      if [ -f "$dir/zen-keyboard-shortcuts.json" ] && [ -f "$dir/prefs.js" ]; then
        ver=$(${pkgs.gnused}/bin/sed -n 's/^user_pref("zen.keyboard.shortcuts.version", \([0-9]*\));$/\1/p' "$dir/prefs.js")
        have=$([ -f "$dir/zen-shortcuts-baseline.json" ] && ${lib.getExe pkgs.jq} -r '.version' "$dir/zen-shortcuts-baseline.json")
        if [ -n "$ver" ] && [ "$ver" != "$have" ]; then
          ${lib.getExe pkgs.jq} --argjson v "$ver" '{version: $v, shortcuts: .shortcuts}' \
            "$dir/zen-keyboard-shortcuts.json" > "$dir/zen-shortcuts-baseline.json"
        fi
      fi
    '') (builtins.attrValues config.programs.zen-browser.profiles)
  );
```

- [ ] **Step 2: Build and inspect the script**

```bash
hmbuild karsa
nix eval --raw .#nixosConfigurations.karsa.config.home-manager.users.matt.home.activation.zen-shortcuts-baseline.data | head -12
```

Expected: a store path, then the script with both profile directories.

- [ ] **Step 3: Commit**

```bash
git add home/programs/zen/default.nix
git commit -m "feat(zen): record a shortcut baseline for zen-reconcile"
```

---

### Task 3: `zen_profile` library: readers and the export command

**Files:**
- Create: `home/programs/zen/zen_profile.py`
- Modify: `home/programs/zen/zen-export.py`
- Create: `home/programs/zen/tests/conftest.py`
- Create: `home/programs/zen/tests/test_export.py`
- Create: `home/programs/zen/tests/test_readers.py`
- Delete: `home/programs/zen/zen-export-test.py`

**Interfaces:**
- Produces in `zen_profile`:
  - `norm_id(raw) -> str`
  - `read_bookmarks(places_path) -> list` (home-manager bookmark tree)
  - `load_session(path) -> dict`, raises `ValueError("<path>: not a mozLz4 file")`
  - `save_session(path, data) -> None` (backs up first)
  - `session_pins(data) -> (spaces, pins, stats)`; `stats` has `pinned`,
    `placeholders`, `folders`
  - `read_prefs(path) -> dict`; `remove_prefs(path, keys) -> None`
  - `read_shortcuts(path) -> dict[id, entry]`;
    `read_baseline(path) -> dict[id, entry]`
  - `zen_running(profile_dir) -> bool`
  - `Profile(name, dir)` with `.key` and `.file(name)`;
    `discover(zen_dir) -> list[Profile]`
  - `Repo(root)` with `.path(rel)`, `.load(rel, default)`, `.save(rel, data)`,
    `.toolbar_file(key)`
  - `export_main(argv) -> None`
- Test fixtures in `conftest.py`: `make_profile(dir)`, `make_repo(root)`,
  `world(tmp_path) -> (Profile, Repo)`.

- [ ] **Step 1: Write the fixtures and failing tests**

`tests/conftest.py`:

```python
import json
import os
import sqlite3
import sys

import lz4.block
import pytest

ZEN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ZEN)

import zen_profile as zp  # noqa: E402

SPACE = "{fd5401f0-7d54-444e-bd4c-0c3784091a9d}"
SPACE_ID = "fd5401f0-7d54-444e-bd4c-0c3784091a9d"
FOLDER = "1775537176380-73"
FOLDER_ID = zp.norm_id(FOLDER)
PLACEHOLDER = "1775537176392-19"
MAIL = "11111111-1111-4111-8111-111111111111"
DOCS = "22222222-2222-4222-8222-222222222222"


def tab(sync, url, essential=False, group=None, label=None):
    t = {
        "pinned": True,
        "zenEssential": essential,
        "zenSyncId": sync,
        "zenWorkspace": SPACE,
        "userContextId": 0,
        "index": 1,
        "entries": [{"url": "https://moved.example/", "title": "Moved"}],
        "_zenPinnedInitialState": {"entry": {"url": url, "title": "Page"}},
    }
    if group:
        t["groupId"] = group
    if label:
        t["zenStaticLabel"] = label
    return t


def session():
    return {
        "tabs": [
            tab("{" + MAIL + "}", "https://mail.example/", essential=True),
            tab(PLACEHOLDER, "about:blank", group=FOLDER),
            tab("{" + DOCS + "}", "https://docs.example/", group=FOLDER, label="Docs"),
            {"pinned": False, "entries": [{"url": "https://loose.example/"}], "index": 1},
        ],
        "folders": [{
            "id": FOLDER, "name": "Work", "pinned": True, "collapsed": True,
            "parentId": None, "emptyTabIds": [PLACEHOLDER], "userIcon": "",
            "workspaceId": SPACE,
        }],
        "spaces": [{"uuid": SPACE, "name": "Main", "icon": "", "position": 1000}],
    }


def write_session(path, data):
    with open(path, "wb") as f:
        f.write(b"mozLz40\0" + lz4.block.compress(json.dumps(data).encode()))


def make_places(d):
    db = sqlite3.connect(os.path.join(d, "places.sqlite"))
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA wal_autocheckpoint=0")
    db.executescript("""
        CREATE TABLE moz_places (id INTEGER PRIMARY KEY, url TEXT);
        CREATE TABLE moz_bookmarks (id INTEGER PRIMARY KEY, type INTEGER,
            fk INTEGER, parent INTEGER, position INTEGER, title TEXT,
            guid TEXT);
        INSERT INTO moz_places VALUES (1, 'https://a.example/'),
            (2, 'https://b.example/'), (3, 'place:sort=8'),
            (4, 'https://c.example/');
        INSERT INTO moz_bookmarks VALUES
            (1, 2, NULL, 0, 0, '', 'root________'),
            (2, 2, NULL, 1, 0, 'menu', 'menu________'),
            (3, 2, NULL, 1, 1, 'toolbar', 'toolbar_____'),
            (4, 2, NULL, 1, 2, 'unfiled', 'unfiled_____'),
            (5, 1, 2, 3, 1, 'B', 'b'),
            (6, 1, 1, 3, 0, NULL, 'a'),
            (7, 2, NULL, 2, 0, 'Dev', 'dev'),
            (8, 3, NULL, 7, 0, NULL, 'sep'),
            (9, 1, 3, 7, 1, 'Recent', 'q'),
            (10, 1, 4, 4, 0, 'C', 'c');
    """)
    db.commit()
    return db


TOOLBAR = {"placements": {"nav-bar": ["back-button", "urlbar-container"]}, "currentVersion": 28}


def pref_line(k, v):
    return f"user_pref({json.dumps(k)}, {json.dumps(v)});\n"


def make_profile(d):
    os.makedirs(d, exist_ok=True)
    make_places(d).close()
    write_session(os.path.join(d, "zen-sessions.jsonlz4"), session())
    declared = {"general.autoScroll": True, "zen.glance.enabled": False,
                "browser.uiCustomization.state": json.dumps(TOOLBAR)}
    live = dict(declared, **{"general.autoScroll": False, "test.pref": True,
                             "app.update.lastUpdateTime": 5,
                             "zen.keyboard.shortcuts.version": 21})
    with open(os.path.join(d, "user.js"), "w") as f:
        f.write("// Generated by Home Manager.\n" + "".join(pref_line(k, v) for k, v in declared.items()))
    with open(os.path.join(d, "prefs.js"), "w") as f:
        f.write("// Mozilla User Preferences\n" + "".join(pref_line(k, v) for k, v in live.items()))
    base = [{"id": "zen-toggle-sidebar", "key": "b", "keycode": None,
             "modifiers": {"alt": True, "accel": False}, "disabled": False},
            {"id": "key_savePage", "key": "s", "keycode": None,
             "modifiers": {"accel": True}, "disabled": False}]
    live_sc = json.loads(json.dumps(base))
    live_sc[0]["key"] = "x"
    with open(os.path.join(d, "zen-keyboard-shortcuts.json"), "w") as f:
        json.dump({"shortcuts": live_sc}, f)
    with open(os.path.join(d, "zen-shortcuts-baseline.json"), "w") as f:
        json.dump({"version": 21, "shortcuts": base}, f)


def make_repo(root):
    zen = os.path.join(root, "home", "programs", "zen")
    for sub in ("profiles", "settings", "shortcuts"):
        os.makedirs(os.path.join(zen, sub), exist_ok=True)

    def dump(rel, data):
        with open(os.path.join(zen, rel), "w") as f:
            json.dump(data, f)

    dump("profiles/personal.json", {
        "bookmarks": [
            {"name": "Bookmarks Toolbar", "toolbar": True, "bookmarks": [
                {"name": "", "url": "https://a.example/"},
                {"name": "Old B", "url": "https://b.example/"},
                {"name": "Gone", "url": "https://gone.example/"},
            ]},
        ],
        "pins": [
            {"id": MAIL, "title": "Page", "editedTitle": False, "url": "https://mail.example/",
             "position": 100, "isEssential": True, "workspace": SPACE_ID,
             "container": None, "folderParentId": None},
            {"id": "33333333-3333-4333-8333-333333333333", "title": "Old pin",
             "editedTitle": False, "url": "https://old.example/", "position": 500,
             "isEssential": False, "workspace": SPACE_ID, "container": None,
             "folderParentId": None},
        ],
        "spaces": [{"id": SPACE_ID, "name": "Main", "icon": None, "position": 1000}],
    })
    dump("toolbar.json", {"placements": {"nav-bar": ["urlbar-container", "back-button"]}, "currentVersion": 28})
    dump("settings/shared.json", {"zen.glance.enabled": False})
    dump("settings/ignore.json", {"setting": ["app.*"]})
    dump("shortcuts/shared.json", [])


@pytest.fixture
def world(tmp_path):
    zen_dir = tmp_path / "zen"
    make_profile(str(zen_dir / "personal"))
    with open(zen_dir / "profiles.ini", "w") as f:
        f.write("[General]\nStartWithLastProfile=1\n\n[Profile0]\nName=Personal\nIsRelative=1\nPath=personal\n")
    make_repo(str(tmp_path / "repo"))
    return zp.discover(str(zen_dir))[0], zp.Repo(str(tmp_path / "repo"))
```

`tests/test_export.py` (the old self-check, as pytest):

```python
import json
import os
import subprocess
import sys
import tempfile

from conftest import FOLDER_ID, SPACE_ID, make_places, session, write_session

SCRIPT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "zen-export.py")


def run(profile, out):
    return subprocess.run([sys.executable, SCRIPT, profile, out], capture_output=True, text=True)


def test_export():
    with tempfile.TemporaryDirectory() as d:
        db = make_places(d)
        write_session(os.path.join(d, "zen-sessions.jsonlz4"), session())
        assert os.path.getsize(os.path.join(d, "places.sqlite-wal")) > 0
        out = os.path.join(d, "out.json")
        r = run(d, out)
        db.close()
        assert r.returncode == 0, r.stderr
        assert "source: 3 pinned tabs, 1 placeholders, 1 folders" in r.stdout
        assert "wrote: 3 bookmarks, 2 pins (1 essentials), 1 folders" in r.stdout
        data = json.load(open(out))
    assert data["bookmarks"] == [
        {"name": "Bookmarks Toolbar", "toolbar": True, "bookmarks": [
            {"name": "", "url": "https://a.example/"},
            {"name": "B", "url": "https://b.example/"},
        ]},
        {"name": "Dev", "bookmarks": []},
        {"name": "Other Bookmarks", "bookmarks": [{"name": "C", "url": "https://c.example/"}]},
    ]
    assert data["spaces"] == [{"id": SPACE_ID, "name": "Main", "icon": None, "position": 1000}]
    assert [p["id"] for p in data["pins"]] == [
        "11111111-1111-4111-8111-111111111111", FOLDER_ID, "22222222-2222-4222-8222-222222222222"]
    assert data["pins"][2]["title"] == "Docs" and data["pins"][2]["folderParentId"] == FOLDER_ID


def test_bad_session():
    with tempfile.TemporaryDirectory() as d:
        make_places(d).close()
        with open(os.path.join(d, "zen-sessions.jsonlz4"), "wb") as f:
            f.write(b"garbage")
        r = run(d, os.path.join(d, "out.json"))
        assert r.returncode != 0
        assert "not a mozLz4 file" in r.stderr
```

`tests/test_readers.py`:

```python
import json
import os

import zen_profile as zp
from conftest import pref_line


def test_read_prefs_handles_escapes_and_json_strings(tmp_path):
    p = tmp_path / "prefs.js"
    p.write_text("// x\n" + pref_line("a.b", 'say "hi"') + pref_line("c", 3)
                 + pref_line("d", json.dumps({"k": [1]})) + "user_pref(\"e\", true);\n")
    assert zp.read_prefs(str(p)) == {"a.b": 'say "hi"', "c": 3, "d": '{"k": [1]}', "e": True}


def test_remove_prefs_backs_up(tmp_path):
    p = tmp_path / "prefs.js"
    p.write_text(pref_line("a", 1) + pref_line("b", 2))
    zp.remove_prefs(str(p), {"a"})
    assert zp.read_prefs(str(p)) == {"b": 2}
    assert (tmp_path / "prefs.js.pre-reconcile").exists()


def test_zen_running(tmp_path):
    assert not zp.zen_running(str(tmp_path))
    os.symlink(f"127.0.0.2:+{os.getpid()}", tmp_path / "lock")
    assert zp.zen_running(str(tmp_path))
    os.remove(tmp_path / "lock")
    os.symlink("127.0.0.2:+999999999", tmp_path / "lock")
    assert not zp.zen_running(str(tmp_path))


def test_discover_and_repo(world):
    profile, repo = world
    assert profile.name == "Personal" and profile.key == "personal"
    assert repo.toolbar_file("personal") == "toolbar.json"
    assert repo.load("missing.json", {"x": 1}) == {"x": 1}


def test_shortcuts_and_baseline(world):
    profile, _ = world
    live = zp.read_shortcuts(profile.file("zen-keyboard-shortcuts.json"))
    base = zp.read_baseline(profile.file("zen-shortcuts-baseline.json"))
    assert live["zen-toggle-sidebar"]["key"] == "x" and base["zen-toggle-sidebar"]["key"] == "b"
```

- [ ] **Step 2: Run the tests to check they fail**

Run: `git rm -q home/programs/zen/zen-export-test.py && eval "$TESTS"`
Expected: errors with `ModuleNotFoundError: No module named 'zen_profile'`.

- [ ] **Step 3: Write `zen_profile.py` (readers)**

```python
import configparser
import json
import os
import re
import shutil
import sqlite3
import sys
import tempfile
import uuid

import lz4.block

MAGIC = b"mozLz40\0"
TOOLBAR_PREF = "browser.uiCustomization.state"
MODIFIERS = ("accel", "alt", "control", "meta", "shift")
BASELINE = "zen-shortcuts-baseline.json"
PREF_RE = re.compile(r'^user_pref\("((?:[^"\\]|\\.)*)",\s*(.*)\);\s*$', re.M)


def norm_id(raw):
    s = raw.strip("{}")
    try:
        return str(uuid.UUID(s))
    except ValueError:
        # Folder ids are "<ms>-<n>", not UUIDs.
        return str(uuid.uuid5(uuid.NAMESPACE_URL, "zen:" + s))


def backup(path):
    if os.path.exists(path):
        shutil.copy2(path, path + ".pre-reconcile")


def read_bookmarks(places):
    if not os.path.exists(places):
        raise ValueError(f"{places}: not found")
    with tempfile.TemporaryDirectory() as tmp:
        # Zen locks the live file and keeps recent writes in the -wal.
        copy = os.path.join(tmp, "places.sqlite")
        for suffix in ("", "-wal"):
            if os.path.exists(places + suffix):
                shutil.copyfile(places + suffix, copy + suffix)
        db = sqlite3.connect(copy)
        rows = db.execute(
            "SELECT b.id, b.parent, b.type, b.title, b.guid, p.url"
            " FROM moz_bookmarks b LEFT JOIN moz_places p ON p.id = b.fk"
            " ORDER BY b.parent, b.position"
        ).fetchall()
        db.close()

    children = {}
    roots = {}
    for id_, parent, type_, title, guid, url in rows:
        children.setdefault(parent, []).append((id_, type_, title, url))
        roots[guid] = id_

    def tree(parent):
        out = []
        for id_, type_, title, url in children.get(parent, []):
            if type_ == 1 and url and not url.startswith("place:"):
                out.append({"name": title or "", "url": url})
            elif type_ == 2:
                out.append({"name": title or "", "bookmarks": tree(id_)})
        return out

    result = []
    toolbar = tree(roots.get("toolbar_____"))
    if toolbar:
        result.append({"name": "Bookmarks Toolbar", "toolbar": True, "bookmarks": toolbar})
    result += tree(roots.get("menu________"))
    other = tree(roots.get("unfiled_____"))
    if other:
        result.append({"name": "Other Bookmarks", "bookmarks": other})
    return result


def load_session(path):
    if not os.path.exists(path):
        raise ValueError(f"{path}: not found")
    with open(path, "rb") as f:
        raw = f.read()
    if raw[:8] != MAGIC:
        raise ValueError(f"{path}: not a mozLz4 file")
    return json.loads(lz4.block.decompress(raw[8:]))


def save_session(path, data):
    backup(path)
    with open(path, "wb") as f:
        f.write(MAGIC + lz4.block.compress(json.dumps(data).encode()))


def entry_of(tab):
    initial = (tab.get("_zenPinnedInitialState") or {}).get("entry")
    if initial:
        return initial
    entries = tab.get("entries") or [{}]
    return entries[min(tab.get("index", 1), len(entries)) - 1]


def session_pins(data):
    folders = [f for f in data.get("folders", []) if f.get("pinned")]
    folder_ids = {f["id"] for f in folders}
    placeholders = {t for f in folders for t in f.get("emptyTabIds", [])}
    spaces = [
        {"id": norm_id(s["uuid"]), "name": s["name"],
         "icon": s.get("icon") or None, "position": s.get("position", 1000)}
        for s in data.get("spaces", [])
    ]
    pinned = [t for t in data.get("tabs", []) if t.get("pinned") or t.get("zenEssential")]
    pins = []
    positions = {}
    skipped = 0
    for i, tab in enumerate(pinned):
        pos = (i + 1) * 100
        group = tab.get("groupId") if tab.get("groupId") in folder_ids else None
        if group:
            positions.setdefault(group, pos - 1)
        if tab.get("zenSyncId") in placeholders:
            skipped += 1
            continue
        entry = entry_of(tab)
        label = tab.get("zenStaticLabel")
        workspace = tab.get("zenWorkspace")
        pins.append({
            "id": norm_id(tab["zenSyncId"]),
            "title": label or entry.get("title") or entry.get("url") or "",
            "editedTitle": bool(label),
            "url": entry.get("url"),
            "position": pos,
            "isEssential": bool(tab.get("zenEssential")),
            "workspace": norm_id(workspace) if workspace else None,
            "container": tab.get("userContextId") or None,
            "folderParentId": norm_id(group) if group else None,
        })
    for _ in folders:
        for f in folders:
            parent = f.get("parentId")
            if parent in folder_ids and f["id"] in positions:
                positions[parent] = min(positions.get(parent, positions[f["id"]]), positions[f["id"]] - 1)
    for f in folders:
        parent = f.get("parentId")
        pins.append({
            "id": norm_id(f["id"]),
            "title": f.get("name") or "",
            "isGroup": True,
            "position": positions.get(f["id"], 1000),
            "isFolderCollapsed": bool(f.get("collapsed")),
            "folderIcon": f.get("userIcon") or None,
            "workspace": norm_id(f["workspaceId"]) if f.get("workspaceId") else None,
            "folderParentId": norm_id(parent) if parent in folder_ids else None,
        })
    pins.sort(key=lambda p: p["position"])
    return spaces, pins, {"pinned": len(pinned), "placeholders": skipped, "folders": len(folders)}


def read_prefs(path):
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as f:
        text = f.read()
    return {json.loads(f'"{k}"'): json.loads(v) for k, v in PREF_RE.findall(text)}


def remove_prefs(path, keys):
    backup(path)
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()
    keep = []
    for line in lines:
        m = PREF_RE.match(line)
        if not (m and json.loads(f'"{m.group(1)}"') in keys):
            keep.append(line)
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(keep)


def _by_id(entries):
    return {e["id"]: e for e in entries if e.get("id")}


def read_shortcuts(path):
    with open(path) as f:
        return _by_id(json.load(f)["shortcuts"])


def read_baseline(path):
    with open(path) as f:
        return _by_id(json.load(f)["shortcuts"])


def zen_running(profile_dir):
    try:
        target = os.readlink(os.path.join(profile_dir, "lock"))
        os.kill(int(target.rpartition("+")[2]), 0)
    except (OSError, ValueError):
        return False
    return True


class Profile:
    def __init__(self, name, dir):
        self.name = name
        self.dir = dir

    @property
    def key(self):
        return os.path.basename(self.dir.rstrip("/")).lower()

    def file(self, name):
        return os.path.join(self.dir, name)


def discover(zen_dir):
    ini = configparser.ConfigParser(interpolation=None)
    ini.optionxform = str
    ini.read(os.path.join(zen_dir, "profiles.ini"))
    out = []
    for s in ini.sections():
        sec = ini[s]
        if s.startswith("Profile") and sec.get("Name") and sec.get("Path"):
            relative = sec.get("IsRelative", "1") == "1"
            out.append(Profile(sec["Name"], os.path.join(zen_dir, sec["Path"]) if relative else sec["Path"]))
    return out


class Repo:
    def __init__(self, root):
        self.zen = os.path.join(root, "home", "programs", "zen")

    def path(self, rel):
        return os.path.join(self.zen, rel)

    def load(self, rel, default):
        p = self.path(rel)
        if not os.path.exists(p):
            return default
        try:
            with open(p) as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            raise ValueError(f"{p}: {e}") from None

    def save(self, rel, data):
        p = self.path(rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w") as f:
            json.dump(data, f, indent=2, sort_keys=True, ensure_ascii=False)
            f.write("\n")
        return rel

    def toolbar_file(self, key):
        own = f"toolbar-{key}.json"
        return own if os.path.exists(self.path(own)) else "toolbar.json"


def count_bookmarks(entries):
    return sum(count_bookmarks(e["bookmarks"]) if "bookmarks" in e else 1 for e in entries)


def export_main(argv):
    if len(argv) != 2:
        sys.exit("usage: zen-export <profile-dir> <out.json>")
    profile, out = argv
    try:
        bookmarks = read_bookmarks(os.path.join(profile, "places.sqlite"))
        spaces, pins, stats = session_pins(load_session(os.path.join(profile, "zen-sessions.jsonlz4")))
    except ValueError as e:
        sys.exit(str(e))
    print(f"source: {stats['pinned']} pinned tabs, {stats['placeholders']} placeholders, {stats['folders']} folders")
    with open(out, "w") as f:
        json.dump({"bookmarks": bookmarks, "pins": pins, "spaces": spaces},
                  f, indent=2, sort_keys=True, ensure_ascii=False)
        f.write("\n")
    tabs = [p for p in pins if not p.get("isGroup")]
    print(f"wrote: {count_bookmarks(bookmarks)} bookmarks, {len(tabs)} pins"
          f" ({sum(p['isEssential'] for p in tabs)} essentials),"
          f" {len(pins) - len(tabs)} folders")
```

Replace `zen-export.py` with:

```python
import sys

from zen_profile import export_main

if __name__ == "__main__":
    export_main(sys.argv[1:])
```

- [ ] **Step 4: Run the tests to check they pass**

Run: `eval "$TESTS"`
Expected: `7 passed`.

- [ ] **Step 5: Commit**

```bash
git add home/programs/zen
git commit -m "refactor(zen): split profile readers into zen_profile"
```

---

### Task 4: Differences

**Files:**
- Modify: `home/programs/zen/zen_profile.py`
- Create: `home/programs/zen/tests/test_diff.py`

**Interfaces:**
- Consumes: Task 3 readers, `Profile`, `Repo`.
- Produces:
  - `Diff(kind, ident, change, live, config, label, revert, extra={})`.
    `kind` in `bookmark pin space toolbar setting shortcut`; `change` in
    `added removed changed renamed moved reordered`; `revert` in
    `restart switch edit`.
  - `diff_bookmarks(live_tree, config_tree)`, `diff_pins(spaces, pins,
    config)`, `diff_toolbar(prefs, toolbar)`, `diff_settings(prefs, declared)`,
    `diff_shortcuts(live, baseline)`; each returns `list[Diff]`.
  - `ignored(ignore, kind, ident) -> bool`
  - `diff_profile(profile, repo) -> (list[Diff], list[str] notes)`
  - `show(value) -> str`
  - Bookmark folder paths are tuples; the toolbar folder is `"[toolbar]"`.

- [ ] **Step 1: Write the failing tests**

`tests/test_diff.py`:

```python
import zen_profile as zp
from conftest import DOCS, FOLDER_ID, MAIL

T = zp.TOOLBAR_FOLDER


def rows(diffs):
    return {(d.kind, d.ident, d.change) for d in diffs}


def test_bookmarks_added_removed_renamed_moved_reordered():
    config = [{"name": "Bookmarks Toolbar", "toolbar": True, "bookmarks": [
        {"name": "A", "url": "https://a/"}, {"name": "B", "url": "https://b/"},
        {"name": "Gone", "url": "https://gone/"}, {"name": "M", "url": "https://m/"}]}]
    live = [{"name": "Bookmarks Toolbar", "toolbar": True, "bookmarks": [
        {"name": "B2", "url": "https://b/"}, {"name": "A", "url": "https://a/"},
        {"name": "New", "url": "https://new/"}]},
        {"name": "Dev", "bookmarks": [{"name": "M", "url": "https://m/"}]}]
    got = rows(zp.diff_bookmarks(live, config))
    assert ("bookmark", "Toolbar|https://new/", "added") in got
    assert ("bookmark", "Toolbar|https://gone/", "removed") in got
    assert ("bookmark", "Toolbar|https://b/", "renamed") in got
    assert ("bookmark", "https://m/", "moved") in got
    assert ("bookmark", "order:Toolbar", "reordered") in got


def test_pins_added_removed_changed_and_space(world):
    profile, repo = world
    spaces, pins, _ = zp.session_pins(zp.load_session(profile.file("zen-sessions.jsonlz4")))
    config = repo.load("profiles/personal.json", {})
    got = rows(zp.diff_pins(spaces, pins, config))
    assert ("pin", DOCS, "added") in got
    assert ("pin", FOLDER_ID, "added") in got
    assert ("pin", "33333333-3333-4333-8333-333333333333", "removed") in got
    assert not any(i == MAIL for _, i, _ in got)


def test_pin_title_only_counts_when_edited():
    base = {"id": "x", "title": "Inbox (3)", "editedTitle": False, "url": "u", "position": 1,
            "isEssential": False, "workspace": None, "folderParentId": None}
    live = dict(base, title="Inbox (9)")
    assert zp.diff_pins([], [live], {"pins": [base], "spaces": []}) == []
    assert rows(zp.diff_pins([], [dict(live, editedTitle=True)], {"pins": [base], "spaces": []})) == {("pin", "x", "changed")}


def test_toolbar_treats_missing_and_empty_alike(world):
    profile, repo = world
    prefs = zp.read_prefs(profile.file("prefs.js"))
    got = zp.diff_toolbar(prefs, {"placements": {"nav-bar": ["urlbar-container", "back-button"], "vertical-tabs": []}})
    assert [(d.ident, d.change) for d in got] == [("nav-bar", "changed")]


def test_settings_declared_changed_and_undeclared(world):
    profile, _ = world
    got = zp.diff_settings(zp.read_prefs(profile.file("prefs.js")), zp.read_prefs(profile.file("user.js")))
    by = {d.ident: d for d in got}
    assert by["general.autoScroll"].change == "changed" and by["general.autoScroll"].revert == "restart"
    assert by["test.pref"].change == "added" and by["test.pref"].revert == "edit"
    assert zp.TOOLBAR_PREF not in by


def test_shortcuts_against_baseline(world):
    profile, _ = world
    got = zp.diff_shortcuts(zp.read_shortcuts(profile.file("zen-keyboard-shortcuts.json")),
                            zp.read_baseline(profile.file("zen-shortcuts-baseline.json")))
    assert rows(got) == {("shortcut", "zen-toggle-sidebar", "changed")}


def test_diff_profile_applies_ignores_but_not_to_declared(world):
    profile, repo = world
    repo.save("settings/ignore.json", {"setting": ["app.*", "general.*", "test.pref"], "pin": [DOCS]})
    diffs, notes = zp.diff_profile(profile, repo)
    idents = {d.ident for d in diffs}
    assert "app.update.lastUpdateTime" not in idents and "test.pref" not in idents
    assert "general.autoScroll" in idents
    assert DOCS not in idents
    assert notes == []
```

- [ ] **Step 2: Run the tests to check they fail**

Run: `eval "$TESTS" -k diff`
Expected: FAIL with `AttributeError: module 'zen_profile' has no attribute 'TOOLBAR_FOLDER'`.

- [ ] **Step 3: Add the diff code to `zen_profile.py`**

```python
from dataclasses import dataclass, field

TOOLBAR_FOLDER = "[toolbar]"
PIN_FIELDS = ("url", "isEssential", "folderParentId", "workspace", "folderIcon")
REVERT_TEXT = {
    "restart": "reverts on the next Zen start",
    "switch": "reverts on the next switch",
    "edit": "edits Zen's files; needs this profile's Zen closed",
}


@dataclass
class Diff:
    kind: str
    ident: str
    change: str
    live: object
    config: object
    label: str
    revert: str
    extra: dict = field(default_factory=dict)


def show(value):
    return "(absent)" if value is None else json.dumps(value, ensure_ascii=False)


def ignored(ignore, kind, ident):
    return any(ident == p or (p.endswith("*") and ident.startswith(p[:-1])) for p in ignore.get(kind, []))


def _show_path(path):
    return "/".join("Toolbar" if p == TOOLBAR_FOLDER else p for p in path) or "Menu"


def flatten_bookmarks(tree, path=()):
    out = []
    for e in tree:
        if "bookmarks" in e:
            out += flatten_bookmarks(e["bookmarks"], path + (TOOLBAR_FOLDER if e.get("toolbar") else e.get("name", ""),))
        elif e.get("url"):
            out.append((path, e["url"], e.get("name", "")))
    return out


def diff_bookmarks(live, config):
    lf, cf = flatten_bookmarks(live), flatten_bookmarks(config)
    L = {(p, u): n for p, u, n in lf}
    C = {(p, u): n for p, u, n in cf}
    only_live = [k for k in L if k not in C]
    only_config = [k for k in C if k not in L]
    diffs = []
    for k in list(only_live):
        url = k[1]
        if [u for _, u in only_live].count(url) == 1 and [u for _, u in only_config].count(url) == 1:
            ck = next(c for c in only_config if c[1] == url)
            diffs.append(Diff("bookmark", url, "moved",
                              {"path": k[0], "url": url, "name": L[k]}, {"path": ck[0], "url": url, "name": C[ck]},
                              f"{_show_path(ck[0])} -> {_show_path(k[0])}: {L[k] or url}", "restart"))
            only_live.remove(k)
            only_config.remove(ck)
    for p, u in only_live:
        diffs.append(Diff("bookmark", f"{_show_path(p)}|{u}", "added", {"path": p, "url": u, "name": L[(p, u)]},
                          None, f"{_show_path(p)}: {L[(p, u)] or u}", "restart"))
    for p, u in only_config:
        diffs.append(Diff("bookmark", f"{_show_path(p)}|{u}", "removed", None, {"path": p, "url": u, "name": C[(p, u)]},
                          f"{_show_path(p)}: {C[(p, u)] or u}", "restart"))
    for k in L.keys() & C.keys():
        if L[k] != C[k]:
            p, u = k
            diffs.append(Diff("bookmark", f"{_show_path(p)}|{u}", "renamed", {"path": p, "url": u, "name": L[k]},
                              {"path": p, "url": u, "name": C[k]}, f"{_show_path(p)}: {C[k]!r} -> {L[k]!r}", "restart"))
    for folder in sorted({p for p, _ in L} & {p for p, _ in C}):
        lo = [u for p, u, _ in lf if p == folder and (p, u) in C]
        co = [u for p, u, _ in cf if p == folder and (p, u) in L]
        if lo != co:
            diffs.append(Diff("bookmark", f"order:{_show_path(folder)}", "reordered", lo, co,
                              f"{_show_path(folder)}: order changed", "restart", {"path": folder}))
    return diffs


def _pin_label(p):
    kind = "essential" if p.get("isEssential") else "folder" if p.get("isGroup") else "pin"
    return f"{kind}: {p.get('title') or p.get('url') or p['id']}"


def diff_pins(live_spaces, live_pins, config):
    diffs = []
    cp = {p["id"]: p for p in config.get("pins", [])}
    lp = {p["id"]: p for p in live_pins}
    for i, p in lp.items():
        if i not in cp:
            diffs.append(Diff("pin", i, "added", p, None, _pin_label(p), "edit"))
            continue
        c = cp[i]
        fields = [f for f in PIN_FIELDS if p.get(f) != c.get(f)]
        if (p.get("editedTitle") or c.get("editedTitle")) and p.get("title") != c.get("title"):
            fields.append("title")
        if fields:
            diffs.append(Diff("pin", i, "changed", p, c, f"{_pin_label(p)} ({', '.join(fields)})", "switch",
                              {"fields": fields}))
    for i, c in cp.items():
        if i not in lp:
            diffs.append(Diff("pin", i, "removed", None, c, _pin_label(c), "switch"))
    lo = [i for i in sorted(lp, key=lambda i: lp[i]["position"]) if i in cp]
    co = [i for i in sorted(cp, key=lambda i: cp[i].get("position", 1000)) if i in lp]
    if lo != co:
        diffs.append(Diff("pin", "order", "reordered", lo, co, "pin order changed", "switch",
                          {"positions": {i: lp[i]["position"] for i in lo}}))
    cs = {s["id"]: s for s in config.get("spaces", [])}
    ls = {s["id"]: s for s in live_spaces}
    for i, s in ls.items():
        if i not in cs:
            diffs.append(Diff("space", i, "added", s, None, f"space: {s['name']}", "edit"))
        elif (s["name"], s.get("icon")) != (cs[i]["name"], cs[i].get("icon")):
            diffs.append(Diff("space", i, "changed", s, cs[i], f"space: {s['name']}", "switch"))
    for i, c in cs.items():
        if i not in ls:
            diffs.append(Diff("space", i, "removed", None, c, f"space: {c['name']}", "switch"))
    return diffs


def diff_toolbar(prefs, toolbar):
    raw = prefs.get(TOOLBAR_PREF)
    if not raw:
        return []
    live = json.loads(raw).get("placements", {})
    conf = toolbar.get("placements", {})
    return [Diff("toolbar", a, "changed", live.get(a) or [], conf.get(a) or [], a, "restart")
            for a in sorted(set(live) | set(conf)) if (live.get(a) or []) != (conf.get(a) or [])]


def diff_settings(prefs, declared):
    diffs = []
    for k, v in prefs.items():
        if k == TOOLBAR_PREF:
            continue
        if k in declared:
            if v != declared[k]:
                diffs.append(Diff("setting", k, "changed", v, declared[k], f"{k} = {show(v)}", "restart"))
        else:
            diffs.append(Diff("setting", k, "added", v, None, f"{k} = {show(v)}", "edit"))
    return diffs


def shortcut_state(entry):
    mods = entry.get("modifiers") or {}
    return {"key": entry.get("key") or "", "keycode": entry.get("keycode") or "",
            "modifiers": [m for m in MODIFIERS if mods.get(m)], "disabled": bool(entry.get("disabled"))}


def _keys(state):
    if state["disabled"]:
        return "disabled"
    return "+".join(state["modifiers"] + [state["key"] or state["keycode"]])


def diff_shortcuts(live, baseline):
    diffs = []
    for i, e in live.items():
        b = baseline.get(i)
        if b is not None and shortcut_state(e) != shortcut_state(b):
            ls, bs = shortcut_state(e), shortcut_state(b)
            diffs.append(Diff("shortcut", i, "changed", ls, bs, f"{i}: {_keys(bs)} -> {_keys(ls)}", "edit"))
    return diffs


def diff_profile(profile, repo):
    ignore = repo.load("settings/ignore.json", {})
    config = repo.load(f"profiles/{profile.key}.json", {})
    diffs, notes = [], []
    if os.path.exists(profile.file("places.sqlite")):
        diffs += diff_bookmarks(read_bookmarks(profile.file("places.sqlite")), config.get("bookmarks", []))
    else:
        notes.append("bookmarks: profile not opened yet")
    if os.path.exists(profile.file("zen-sessions.jsonlz4")):
        spaces, pins, _ = session_pins(load_session(profile.file("zen-sessions.jsonlz4")))
        diffs += diff_pins(spaces, pins, config)
    else:
        notes.append("pins: profile not opened yet")
    prefs = read_prefs(profile.file("prefs.js"))
    diffs += diff_toolbar(prefs, repo.load(repo.toolbar_file(profile.key), {}))
    diffs += diff_settings(prefs, read_prefs(profile.file("user.js")))
    live_sc, base_sc = profile.file("zen-keyboard-shortcuts.json"), profile.file(BASELINE)
    if os.path.exists(live_sc) and os.path.exists(base_sc):
        diffs += diff_shortcuts(read_shortcuts(live_sc), read_baseline(base_sc))
    else:
        notes.append("shortcuts: no baseline yet; switch once with Zen closed")
    keep = [d for d in diffs
            if (d.kind == "setting" and d.change == "changed") or not ignored(ignore, d.kind, d.ident)]
    return keep, notes
```

- [ ] **Step 4: Run the tests to check they pass**

Run: `eval "$TESTS"`
Expected: `14 passed`.

- [ ] **Step 5: Commit**

```bash
git add home/programs/zen
git commit -m "feat(zen): compute profile differences for zen-reconcile"
```

---

### Task 5: Applying promote, revert and ignore

**Files:**
- Modify: `home/programs/zen/zen_profile.py`
- Create: `home/programs/zen/tests/test_apply.py`

**Interfaces:**
- Consumes: Task 4 `Diff`, readers and writers.
- Produces:
  - `Action(diff, verb, target="shared")`; `verb` in `promote revert ignore`;
    `target` in `shared profile`.
  - `Result` with `written` (set of repo-relative paths), `reverted`,
    `queued`, `restart`, `switch` (lists of `Diff`).
  - `apply(profile, repo, actions) -> Result`
  - `summary(result) -> str`

- [ ] **Step 1: Write the failing tests**

`tests/test_apply.py`:

```python
import json
import os

import zen_profile as zp
from conftest import DOCS, FOLDER_ID


def find(diffs, ident):
    return next(d for d in diffs if d.ident == ident)


def test_promote_setting_to_shared_and_profile(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    res = zp.apply(profile, repo, [zp.Action(find(diffs, "test.pref"), "promote", "shared"),
                                   zp.Action(find(diffs, "general.autoScroll"), "promote", "profile")])
    assert repo.load("settings/shared.json", {})["test.pref"] is True
    assert repo.load("settings/personal.json", {}) == {"general.autoScroll": False}
    assert res.written == {"settings/shared.json", "settings/personal.json"}


def test_promote_pin_keeps_bookmarks_unmanaged(world):
    profile, repo = world
    os.remove(repo.path("profiles/personal.json"))
    diffs, _ = zp.diff_profile(profile, repo)
    zp.apply(profile, repo, [zp.Action(find(diffs, DOCS), "promote")])
    data = repo.load("profiles/personal.json", {})
    assert "bookmarks" not in data
    assert [p["id"] for p in data["pins"]] == [DOCS]


def test_promote_bookmark_removed_added_renamed(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    zp.apply(profile, repo, [zp.Action(find(diffs, "Toolbar|https://gone.example/"), "promote"),
                             zp.Action(find(diffs, "Other Bookmarks|https://c.example/"), "promote"),
                             zp.Action(find(diffs, "Toolbar|https://b.example/"), "promote")])
    tree = repo.load("profiles/personal.json", {})["bookmarks"]
    assert zp.flatten_bookmarks(tree) == [
        (("[toolbar]",), "https://a.example/", ""),
        (("[toolbar]",), "https://b.example/", "B"),
        (("Other Bookmarks",), "https://c.example/", "C"),
    ]


def test_promote_toolbar_profile_creates_own_file(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    zp.apply(profile, repo, [zp.Action(find(diffs, "nav-bar"), "promote", "profile")])
    assert repo.load("toolbar-personal.json", {})["placements"]["nav-bar"] == ["back-button", "urlbar-container"]
    assert repo.load("toolbar.json", {})["placements"]["nav-bar"] == ["urlbar-container", "back-button"]


def test_promote_shortcut_updates_baseline(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    zp.apply(profile, repo, [zp.Action(find(diffs, "zen-toggle-sidebar"), "promote")])
    entry = repo.load("shortcuts/shared.json", [])[0]
    assert entry["id"] == "zen-toggle-sidebar" and entry["key"] == "x" and entry["modifiers"]["alt"] is True
    assert zp.read_baseline(profile.file(zp.BASELINE))["zen-toggle-sidebar"]["key"] == "x"


def test_ignore_writes_ignore_list(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    zp.apply(profile, repo, [zp.Action(find(diffs, "test.pref"), "ignore")])
    assert "test.pref" in repo.load("settings/ignore.json", {})["setting"]


def test_reverts_edit_files_when_closed(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    res = zp.apply(profile, repo, [zp.Action(find(diffs, "test.pref"), "revert"),
                                   zp.Action(find(diffs, FOLDER_ID), "revert"),
                                   zp.Action(find(diffs, "zen-toggle-sidebar"), "revert"),
                                   zp.Action(find(diffs, "general.autoScroll"), "revert")])
    assert "test.pref" not in zp.read_prefs(profile.file("prefs.js"))
    _, pins, _ = zp.session_pins(zp.load_session(profile.file("zen-sessions.jsonlz4")))
    assert FOLDER_ID not in {p["id"] for p in pins}
    assert DOCS in {p["id"] for p in pins} and next(p for p in pins if p["id"] == DOCS)["folderParentId"] is None
    assert zp.read_shortcuts(profile.file("zen-keyboard-shortcuts.json"))["zen-toggle-sidebar"]["key"] == "b"
    assert [d.ident for d in res.restart] == ["general.autoScroll"]
    assert os.path.exists(profile.file("prefs.js.pre-reconcile"))


def test_reverts_queue_while_zen_runs(world):
    profile, repo = world
    os.symlink(f"127.0.0.2:+{os.getpid()}", profile.file("lock"))
    diffs, _ = zp.diff_profile(profile, repo)
    res = zp.apply(profile, repo, [zp.Action(find(diffs, "test.pref"), "revert")])
    assert [d.ident for d in res.queued] == ["test.pref"]
    assert "test.pref" in zp.read_prefs(profile.file("prefs.js"))
    assert "close Zen" in zp.summary(res)
```

- [ ] **Step 2: Run the tests to check they fail**

Run: `eval "$TESTS" -k apply`
Expected: FAIL with `AttributeError: module 'zen_profile' has no attribute 'Action'`.

- [ ] **Step 3: Add the apply code to `zen_profile.py`**

```python
@dataclass
class Action:
    diff: Diff
    verb: str
    target: str = "shared"


@dataclass
class Result:
    written: set = field(default_factory=set)
    reverted: list = field(default_factory=list)
    queued: list = field(default_factory=list)
    restart: list = field(default_factory=list)
    switch: list = field(default_factory=list)


def _folder(tree, path, create):
    level = tree
    for name in path:
        if name == TOOLBAR_FOLDER:
            node = next((e for e in level if e.get("toolbar")), None)
            if node is None and create:
                node = {"name": "Bookmarks Toolbar", "toolbar": True, "bookmarks": []}
                level.insert(0, node)
        else:
            node = next((e for e in level if "bookmarks" in e and not e.get("toolbar") and e.get("name") == name), None)
            if node is None and create:
                node = {"name": name, "bookmarks": []}
                level.append(node)
        if node is None:
            return None
        level = node["bookmarks"]
    return level


def _insert_bookmark(config, live, path, url, name):
    folder = _folder(config, path, True)
    siblings = [u for p, u, _ in flatten_bookmarks(live) if p == path]
    before = set(siblings[:siblings.index(url)]) if url in siblings else set()
    pos = 0
    for i, e in enumerate(folder):
        if e.get("url") in before:
            pos = i + 1
    folder.insert(pos, {"name": name, "url": url})


def _remove_bookmark(config, path, url):
    folder = _folder(config, path, False)
    if folder is not None:
        folder[:] = [e for e in folder if e.get("url") != url]


def _promote_bookmark(config, live, d):
    tree = config.setdefault("bookmarks", [])
    if d.change == "added":
        _insert_bookmark(tree, live, d.live["path"], d.live["url"], d.live["name"])
    elif d.change == "removed":
        _remove_bookmark(tree, d.config["path"], d.config["url"])
    elif d.change == "renamed":
        for e in _folder(tree, d.live["path"], False) or []:
            if e.get("url") == d.live["url"]:
                e["name"] = d.live["name"]
    elif d.change == "moved":
        _remove_bookmark(tree, d.config["path"], d.ident)
        _insert_bookmark(tree, live, d.live["path"], d.ident, d.live["name"])
    elif d.change == "reordered":
        folder = _folder(tree, d.extra["path"], False) or []
        slots = [i for i, e in enumerate(folder) if "url" in e]
        rank = {u: i for i, u in enumerate(d.live)}
        items = sorted((folder[i] for i in slots), key=lambda e: rank.get(e["url"], len(rank)))
        for i, e in zip(slots, items):
            folder[i] = e


def _promote_pin(config, d):
    pins = config.setdefault("pins", [])
    spaces = config.setdefault("spaces", [])
    if d.kind == "space":
        spaces[:] = [s for s in spaces if s["id"] != d.ident]
        if d.change != "removed":
            spaces.append(d.live)
        return
    if d.change == "reordered":
        # ponytail: copies live positions as-is; ties with config-only pins keep file order.
        for p in pins:
            p["position"] = d.extra["positions"].get(p["id"], p["position"])
    else:
        pins[:] = [p for p in pins if p["id"] != d.ident]
        if d.change != "removed":
            pins.append(d.live)
    pins.sort(key=lambda p: p.get("position", 1000))


def _flake_shortcut(entry):
    mods = entry.get("modifiers") or {}
    return {"id": entry["id"], "key": entry.get("key"), "keycode": entry.get("keycode"),
            "modifiers": {m: bool(mods.get(m)) for m in MODIFIERS}, "disabled": bool(entry.get("disabled"))}


def _revert_session(data, pin_ids, space_ids):
    raw_folders = {f["id"] for f in data.get("folders", []) if norm_id(f["id"]) in pin_ids}
    placeholders = {t for f in data.get("folders", []) if f["id"] in raw_folders for t in f.get("emptyTabIds", [])}
    data["folders"] = [f for f in data.get("folders", []) if f["id"] not in raw_folders]
    tabs = []
    for t in data.get("tabs", []):
        sid = t.get("zenSyncId")
        if sid in placeholders:
            continue
        if (t.get("pinned") or t.get("zenEssential")) and sid and norm_id(sid) in pin_ids:
            continue
        if t.get("groupId") in raw_folders:
            t["groupId"] = None
        tabs.append(t)
    data["tabs"] = tabs
    raw_spaces = {s["uuid"] for s in data.get("spaces", []) if norm_id(s["uuid"]) in space_ids}
    if raw_spaces:
        data["spaces"] = [s for s in data["spaces"] if s["uuid"] not in raw_spaces]
        fallback = data["spaces"][0]["uuid"] if data["spaces"] else None
        for t in data["tabs"]:
            if t.get("zenWorkspace") in raw_spaces:
                t["zenWorkspace"] = fallback
    return data


def apply(profile, repo, actions):
    res = Result()
    profile_rel = f"profiles/{profile.key}.json"
    config = None
    live_tree = None
    for a in actions:
        d = a.diff
        if a.verb == "ignore":
            ignore = repo.load("settings/ignore.json", {})
            if d.ident not in ignore.setdefault(d.kind, []):
                ignore[d.kind].append(d.ident)
            res.written.add(repo.save("settings/ignore.json", ignore))
        elif a.verb == "promote":
            if d.kind in ("bookmark", "pin", "space"):
                if config is None:
                    config = repo.load(profile_rel, {})
                if d.kind == "bookmark":
                    if live_tree is None:
                        live_tree = read_bookmarks(profile.file("places.sqlite"))
                    _promote_bookmark(config, live_tree, d)
                else:
                    _promote_pin(config, d)
            elif d.kind == "toolbar":
                rel = repo.toolbar_file(profile.key)
                data = repo.load(rel, {})
                if a.target == "profile" and rel == "toolbar.json":
                    rel = f"toolbar-{profile.key}.json"
                data.setdefault("placements", {})[d.ident] = d.live
                res.written.add(repo.save(rel, data))
            elif d.kind == "setting":
                rel = "settings/shared.json" if a.target == "shared" else f"settings/{profile.key}.json"
                data = repo.load(rel, {})
                data[d.ident] = d.live
                res.written.add(repo.save(rel, data))
            elif d.kind == "shortcut":
                rel = "shortcuts/shared.json" if a.target == "shared" else f"shortcuts/{profile.key}.json"
                live = read_shortcuts(profile.file("zen-keyboard-shortcuts.json"))[d.ident]
                data = [e for e in repo.load(rel, []) if e.get("id") != d.ident] + [_flake_shortcut(live)]
                res.written.add(repo.save(rel, data))
                with open(profile.file(BASELINE)) as f:
                    base = json.load(f)
                base["shortcuts"] = [live if e.get("id") == d.ident else e for e in base["shortcuts"]]
                with open(profile.file(BASELINE), "w") as f:
                    json.dump(base, f)
        elif d.revert == "restart":
            res.restart.append(d)
        elif d.revert == "switch":
            res.switch.append(d)
        else:
            res.queued.append(d)
    if config is not None:
        res.written.add(repo.save(profile_rel, config))
    if res.queued and not zen_running(profile.dir):
        _apply_edits(profile, res.queued)
        res.reverted, res.queued = res.queued, []
    return res


def _apply_edits(profile, diffs):
    prefs = {d.ident for d in diffs if d.kind == "setting"}
    if prefs:
        remove_prefs(profile.file("prefs.js"), prefs)
    pin_ids = {d.ident for d in diffs if d.kind == "pin"}
    space_ids = {d.ident for d in diffs if d.kind == "space"}
    if pin_ids or space_ids:
        path = profile.file("zen-sessions.jsonlz4")
        save_session(path, _revert_session(load_session(path), pin_ids, space_ids))
    shortcuts = {d.ident for d in diffs if d.kind == "shortcut"}
    if shortcuts:
        path = profile.file("zen-keyboard-shortcuts.json")
        base = read_baseline(profile.file(BASELINE))
        with open(path) as f:
            data = json.load(f)
        backup(path)
        for e in data["shortcuts"]:
            if e.get("id") in shortcuts:
                for k in ("key", "keycode", "modifiers", "disabled"):
                    e[k] = base[e["id"]].get(k)
        with open(path, "w") as f:
            json.dump(data, f)


def summary(res):
    lines = []
    if res.written:
        lines += ["Repo files written:"] + [f"  home/programs/zen/{r}" for r in sorted(res.written)]
        lines += ["Next: git add, git diff, commit, then nixswitch."]
    if res.reverted:
        lines.append(f"Reverted now: {len(res.reverted)}")
    if res.restart:
        lines.append(f"Revert on the next Zen start: {len(res.restart)}")
    if res.switch:
        lines.append(f"Revert on the next switch: {len(res.switch)}")
    if res.queued:
        lines.append(f"Queued, close Zen to apply: {len(res.queued)}")
    return "\n".join(lines) or "Nothing to do."
```

- [ ] **Step 4: Run the tests to check they pass**

Run: `eval "$TESTS"`
Expected: `22 passed`.

- [ ] **Step 5: Commit**

```bash
git add home/programs/zen
git commit -m "feat(zen): apply promote, revert and ignore for zen-reconcile"
```

---

### Task 6: The TUI

**Files:**
- Create: `home/programs/zen/zen-reconcile.py`
- Create: `home/programs/zen/tests/test_tui.py`

**Interfaces:**
- Consumes: `zen_profile.discover`, `diff_profile`, `apply`, `summary`,
  `zen_running`, `Action`, `show`, `REVERT_TEXT`.
- Produces: `ReconcileApp(repo, profiles)`; `main(argv)` with
  `--repo` (default `~/nixos-config`), `--zen-dir` (default
  `~/.config/zen`) and `--profile NAME`.

- [ ] **Step 1: Write the failing pilot tests**

`tests/test_tui.py`:

```python
import asyncio
import importlib.util
import os

from textual.widgets import DataTable

ZEN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location("zen_reconcile", os.path.join(ZEN, "zen-reconcile.py"))
zr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(zr)


def run(app, *keys, select=None):
    async def go():
        async with app.run_test() as pilot:
            if select:
                idx = [d.ident for d in app.visible()].index(select)
                app.query_one(DataTable).move_cursor(row=idx)
                await pilot.pause()
            await pilot.press(*keys)
            await pilot.pause()
    asyncio.run(go())


def test_promote_then_apply(world):
    profile, repo = world
    app = zr.ReconcileApp(repo, [profile])
    run(app, "p", "a", "y", "escape", select="test.pref")
    assert repo.load("settings/shared.json", {})["test.pref"] is True


def test_target_toggle_writes_profile_file(world):
    profile, repo = world
    app = zr.ReconcileApp(repo, [profile])
    run(app, "p", "up", "t", "a", "y", "escape", select="test.pref")
    assert repo.load("settings/personal.json", {})["test.pref"] is True


def test_apply_declined_writes_nothing(world):
    profile, repo = world
    app = zr.ReconcileApp(repo, [profile])
    run(app, "p", "a", "n", select="test.pref")
    assert "test.pref" not in repo.load("settings/shared.json", {})
```

- [ ] **Step 2: Run the tests to check they fail**

Run: `eval "$TESTS" -k tui`
Expected: errors with `FileNotFoundError` for `zen-reconcile.py`.

- [ ] **Step 3: Write `zen-reconcile.py`**

```python
import argparse
import os
import sys

from textual.app import App
from textual.binding import Binding
from textual.screen import ModalScreen
from textual.widgets import DataTable, Footer, Header, Static

import zen_profile as zp

KINDS = [None, "bookmark", "pin", "space", "toolbar", "setting", "shortcut"]
MARKS = {"promote": "P", "revert": "R", "ignore": "I"}


class Confirm(ModalScreen):
    BINDINGS = [Binding("y", "answer(True)", "Yes"), Binding("n", "answer(False)", "No"),
                Binding("escape", "answer(False)", "No")]

    def __init__(self, text):
        super().__init__()
        self.text = text

    def compose(self):
        yield Static(self.text + "\n\n[y] yes   [n] no", id="dialog")

    def action_answer(self, value):
        self.dismiss(value)


class Message(ModalScreen):
    BINDINGS = [Binding("escape", "close", "Close"), Binding("enter", "close", "Close")]

    def __init__(self, text):
        super().__init__()
        self.text = text

    def compose(self):
        yield Static(self.text + "\n\n[enter] close", id="dialog")

    def action_close(self):
        self.dismiss(None)


class ReconcileApp(App):
    CSS = """
    #status { height: 1; }
    #detail { height: 8; border: solid $accent; }
    #dialog { width: 80; height: auto; border: thick $accent; padding: 1 2; background: $surface; }
    Confirm, Message { align: center middle; }
    """
    BINDINGS = [
        Binding("p", "mark('promote')", "Promote"), Binding("r", "mark('revert')", "Revert"),
        Binding("s", "mark('skip')", "Skip"), Binding("i", "mark('ignore')", "Ignore"),
        Binding("t", "target", "Target"), Binding("f", "filter", "Filter"),
        Binding("n", "next_profile", "Profile"), Binding("a", "apply", "Apply"),
        Binding("q", "quit", "Quit"),
    ]

    def __init__(self, repo, profiles):
        super().__init__()
        self.repo = repo
        self.profiles = profiles
        self.index = 0
        self.kind = None
        self.diffs = []
        self.notes = []
        self.marks = {}

    def compose(self):
        yield Header()
        yield Static(id="status")
        yield DataTable(id="diffs", cursor_type="row")
        yield Static(id="detail")
        yield Footer()

    def on_mount(self):
        self.cols = self.query_one(DataTable).add_columns("", "kind", "change", "item", "revert")
        self.reload()

    @property
    def profile(self):
        return self.profiles[self.index]

    def reload(self):
        try:
            self.diffs, self.notes = zp.diff_profile(self.profile, self.repo)
        except ValueError as e:
            self.diffs, self.notes = [], [str(e)]
        self.refresh_table()

    def visible(self):
        return [d for d in self.diffs if self.kind in (None, d.kind)]

    def mark_text(self, d):
        m = self.marks.get((d.kind, d.ident))
        return "" if not m else MARKS[m[0]] + ("*" if m[1] == "profile" else "")

    def refresh_table(self):
        table = self.query_one(DataTable)
        table.clear()
        for d in self.visible():
            table.add_row(self.mark_text(d), d.kind, d.change, d.label[:90], d.revert, key=f"{d.kind}\0{d.ident}")
        state = "Zen open" if zp.zen_running(self.profile.dir) else "Zen closed"
        notes = ("  |  " + "; ".join(self.notes)) if self.notes else ""
        self.query_one("#status", Static).update(
            f"{self.profile.name} ({state})  filter: {self.kind or 'all'}  {len(self.visible())} differences{notes}")
        self.show_detail()

    def current(self):
        rows = self.visible()
        row = self.query_one(DataTable).cursor_row
        return rows[row] if rows and 0 <= row < len(rows) else None

    def show_detail(self):
        d = self.current()
        text = "" if d is None else (f"live:   {zp.show(d.live)}\nconfig: {zp.show(d.config)}\n"
                                     f"revert: {zp.REVERT_TEXT[d.revert]}")
        self.query_one("#detail", Static).update(text)

    def on_data_table_row_highlighted(self, event):
        self.show_detail()

    def update_mark(self, d):
        table = self.query_one(DataTable)
        table.update_cell(f"{d.kind}\0{d.ident}", self.cols[0], self.mark_text(d))

    def action_mark(self, verb):
        d = self.current()
        if d is None:
            return
        key = (d.kind, d.ident)
        if verb == "skip":
            self.marks.pop(key, None)
        else:
            self.marks[key] = (verb, self.marks.get(key, (None, "shared"))[1])
        self.update_mark(d)
        table = self.query_one(DataTable)
        table.move_cursor(row=min(table.cursor_row + 1, len(self.visible()) - 1))

    def action_target(self):
        d = self.current()
        key = d and (d.kind, d.ident)
        if key in self.marks and d.kind in ("setting", "shortcut", "toolbar"):
            verb, target = self.marks[key]
            self.marks[key] = (verb, "profile" if target == "shared" else "shared")
            self.update_mark(d)

    def action_filter(self):
        self.kind = KINDS[(KINDS.index(self.kind) + 1) % len(KINDS)]
        self.refresh_table()

    def action_next_profile(self):
        self.index = (self.index + 1) % len(self.profiles)
        self.marks = {}
        self.kind = None
        self.reload()

    def action_apply(self):
        actions = [zp.Action(d, *self.marks[(d.kind, d.ident)]) for d in self.diffs if (d.kind, d.ident) in self.marks]
        if not actions:
            return
        warn = ""
        unmanaged = "bookmarks" not in self.repo.load(f"profiles/{self.profile.key}.json", {})
        if unmanaged and any(a.verb == "promote" and a.diff.kind == "bookmark" for a in actions):
            warn = ("\n\nThis makes this profile's bookmarks declarative: on the next start Zen keeps only "
                    "the promoted ones.")

        def done(ok):
            if not ok:
                return
            res = zp.apply(self.profile, self.repo, actions)
            self.marks = {}
            self.reload()
            self.push_screen(Message(zp.summary(res)))

        self.push_screen(Confirm(f"Apply {len(actions)} actions to {self.profile.name}?{warn}"), done)


def main(argv):
    ap = argparse.ArgumentParser(prog="zen-reconcile")
    ap.add_argument("--repo", default=os.path.expanduser("~/nixos-config"))
    ap.add_argument("--zen-dir", default=os.path.expanduser("~/.config/zen"))
    ap.add_argument("--profile")
    args = ap.parse_args(argv)
    profiles = zp.discover(args.zen_dir)
    if args.profile:
        profiles = [p for p in profiles if p.name.lower() == args.profile.lower()]
    if not profiles:
        sys.exit(f"no Zen profiles found in {args.zen_dir}")
    ReconcileApp(zp.Repo(args.repo), profiles).run()


if __name__ == "__main__":
    main(sys.argv[1:])
```

- [ ] **Step 4: Run the tests to check they pass**

Run: `eval "$TESTS"`
Expected: `25 passed`.

- [ ] **Step 5: Commit**

```bash
git add home/programs/zen
git commit -m "feat(zen): add the zen-reconcile TUI"
```

---

### Task 7: Package the commands

**Files:**
- Modify: `home/programs/zen/default.nix`

**Interfaces:**
- Consumes: `zen_profile.py`, `zen-export.py`, `zen-reconcile.py`.
- Produces: `zen-export` and `zen-reconcile` on `PATH`.

- [ ] **Step 1: Replace the `home.packages` entry**

Replace the `(pkgs.writers.writePython3Bin "zen-export" ...)` item with:

```nix
    (
      let
        py = pkgs.python3.withPackages (p: [
          p.lz4
          p.textual
        ]);
      in
      pkgs.runCommand "zen-tools" { } ''
        mkdir -p $out/bin $out/lib/zen-tools
        cp ${./zen_profile.py} $out/lib/zen-tools/zen_profile.py
        cp ${./zen-export.py} $out/lib/zen-tools/zen-export.py
        cp ${./zen-reconcile.py} $out/lib/zen-tools/zen-reconcile.py
        for t in zen-export zen-reconcile; do
          printf '#!/bin/sh\nexec %s %s "$@"\n' ${py}/bin/python3 $out/lib/zen-tools/$t.py > $out/bin/$t
          chmod +x $out/bin/$t
        done
      ''
    )
```

- [ ] **Step 2: Build and smoke-test**

```bash
hmbuild karsa
out=$(nix build --no-link --print-out-paths .#nixosConfigurations.karsa.config.home-manager.users.matt.home.path)
$out/bin/zen-reconcile --help
$out/bin/zen-export 2>&1 | tail -1
```

Expected: argparse usage for `zen-reconcile`, then
`usage: zen-export <profile-dir> <out.json>`.

- [ ] **Step 3: Commit**

```bash
git add home/programs/zen/default.nix
git commit -m "build(zen): package zen-export and zen-reconcile"
```

---

### Task 8: Manual test with the user

**Files:** none.

Run on Karsa after the user's `nixswitch`. Each step needs the user.

- [ ] **Step 1: Make one change of each kind in Zen**

Ask the user to, in Personal:
- add a toolbar bookmark and rename another
- pin a new tab and unpin an existing pin
- move one toolbar button
- change one setting in `about:config` (for example `general.autoScroll`)
- rebind one shortcut in Zen's shortcut settings

- [ ] **Step 2: Run the tool**

The user runs `zen-reconcile`. Expected: one row for each change, plus any
undeclared settings not yet ignored.

- [ ] **Step 3: Promote some, revert others**

The user promotes the bookmark, pin and setting; reverts the toolbar move and
the shortcut; ignores one Zen-internal setting. Then `a`, `y`. Check the
summary lists the repo files and the reverts.

- [ ] **Step 4: Confirm the results**

Show `git diff` to the user. After they close Zen and run `nixswitch`, then
reopen Zen, `zen-reconcile` should show none of the handled rows.
