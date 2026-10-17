# Declarative Zen profiles implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every host gets Personal and Professional Zen profiles, and work
hosts add a default Work profile, all declared in this repo.

**Architecture:** The zen-browser-flake home-manager module declares the
profiles. A shared `lib.nix` builds each profile from a JSON data file
(bookmarks, spaces, pins) plus the shared extensions, mods and settings. A
Python export script writes those JSON files from a live profile.

**Tech Stack:** Nix, home-manager, `0xc000022070/zen-browser-flake`
(`homeModules.beta`), rycee `firefox-addons` flake overlay, Python 3 with
`lz4`, SQLite.

**Spec:** `docs/superpowers/specs/2026-10-17-zen-profiles-design.md`

## Global constraints

- Profiles: Personal (`id = 0`, `path = "personal"`), Professional (`id = 1`,
  `path = "professional"`), Work (`id = 2`, `path = "work"`).
- Personal is the default on personal hosts; Work is the default on Tehol and
  Samar.
- `pinsForce` and `spacesForce` stay `false`.
- Work extensions: the shared set plus 1Password. No Bitwarden, LeechBlock NG,
  7TV, BetterTTV or Toolkit for YNAB.
- Old profile folders are never edited or deleted.
- The repo is public. The user reviews every `profiles/*.json` diff before it
  is committed.
- Flakes only see tracked files: `git add` new files before any `nix build`.
- Commit messages use Conventional Commits.
- Comments follow `~/.claude/standards/comment-rules.md`: only constraints and
  gotchas, at most 2 lines.

Commands used throughout:

```bash
# Python with lz4, for running the export script and its test
PYLZ4='nix shell --impure --expr "with import <nixpkgs> {}; python3.withPackages (p: [p.lz4])" -c python3 -I'

# Build a host's home-manager activation package
hmbuild() { nix build --no-link --print-out-paths ".#nixosConfigurations.$1.config.home-manager.users.matt.home.activationPackage"; }
```

## Review focus

- Zen running during export: bookmarks still only in `places.sqlite-wal` must
  be exported. Task 1 tests this.
- Pin folders: the hidden placeholder tab is skipped and children point at the
  folder's mapped ID. Task 1 tests this.
- A pin whose page has moved since pinning: the pinned URL and edited title
  win over the current page. Task 1 tests this.
- Firefox Sync and declared bookmarks: Zen re-imports bookmarks on each start,
  and Sync would push that to other devices. Task 2 disables the bookmarks
  engine and checks `user.js`.
- Zen open during a switch: the flake skips pins and prints "skipped". Tasks 6
  and 7 switch a second time and check for that message.

---

### Task 1: Export script and self-check

**Files:**
- Create: `home/programs/zen/zen-export.py`
- Test: `home/programs/zen/zen-export-test.py`

**Interfaces:**
- Produces: `zen-export.py <profile-dir> <out.json>`. Writes
  `{"bookmarks": [...], "pins": [...], "spaces": [...]}`:
  - `bookmarks`: home-manager bookmark entries (`name` with `url`, or `name`
    with `bookmarks`; the toolbar entry has `toolbar = true`).
  - `spaces`: `{id, name, icon, position}`.
  - `pins`: tabs `{id, title, editedTitle, url, position, isEssential,
    workspace, container, folderParentId}` and folders `{id, title, isGroup,
    position, isFolderCollapsed, folderIcon, workspace, folderParentId}`,
    sorted by `position`.
  - Prints `source: <n> pinned tabs, <m> placeholders, <f> folders` and
    `wrote: <b> bookmarks, <p> pins (<e> essentials), <f> folders`.

- [ ] **Step 1: Write the failing test**

`home/programs/zen/zen-export-test.py`:

```python
import json
import os
import sqlite3
import subprocess
import sys
import tempfile
import uuid

import lz4.block

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "zen-export.py")
SPACE = "{fd5401f0-7d54-444e-bd4c-0c3784091a9d}"
SPACE_ID = "fd5401f0-7d54-444e-bd4c-0c3784091a9d"
FOLDER = "1775537176380-73"
FOLDER_ID = str(uuid.uuid5(uuid.NAMESPACE_URL, "zen:" + FOLDER))
PLACEHOLDER = "1775537176392-19"


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


def make_profile(d):
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
            (6, 1, 1, 3, 0, 'A', 'a'),
            (7, 2, NULL, 2, 0, 'Dev', 'dev'),
            (8, 3, NULL, 7, 0, NULL, 'sep'),
            (9, 1, 3, 7, 1, 'Recent', 'q'),
            (10, 1, 4, 4, 0, 'C', 'c');
    """)
    db.commit()
    session = {
        "tabs": [
            tab("{11111111-1111-4111-8111-111111111111}", "https://mail.example/", essential=True),
            tab(PLACEHOLDER, "about:blank", group=FOLDER),
            tab("{22222222-2222-4222-8222-222222222222}", "https://docs.example/", group=FOLDER, label="Docs"),
            {"pinned": False, "entries": [{"url": "https://loose.example/"}], "index": 1},
        ],
        "folders": [{
            "id": FOLDER, "name": "Work", "pinned": True, "collapsed": True,
            "parentId": None, "emptyTabIds": [PLACEHOLDER], "userIcon": "",
            "workspaceId": SPACE,
        }],
        "spaces": [{"uuid": SPACE, "name": "Main", "icon": "", "position": 1000}],
    }
    with open(os.path.join(d, "zen-sessions.jsonlz4"), "wb") as f:
        f.write(b"mozLz40\0" + lz4.block.compress(json.dumps(session).encode()))
    return db


def run(profile, out):
    return subprocess.run([sys.executable, "-I", SCRIPT, profile, out],
                          capture_output=True, text=True)


def test_export():
    with tempfile.TemporaryDirectory() as d:
        db = make_profile(d)
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
            {"name": "A", "url": "https://a.example/"},
            {"name": "B", "url": "https://b.example/"},
        ]},
        {"name": "Dev", "bookmarks": []},
        {"name": "Other Bookmarks", "bookmarks": [
            {"name": "C", "url": "https://c.example/"},
        ]},
    ]
    assert data["spaces"] == [
        {"id": SPACE_ID, "name": "Main", "icon": None, "position": 1000},
    ]
    assert data["pins"] == [
        {"id": "11111111-1111-4111-8111-111111111111", "title": "Page",
         "editedTitle": False, "url": "https://mail.example/",
         "position": 100, "isEssential": True, "workspace": SPACE_ID,
         "container": None, "folderParentId": None},
        {"id": FOLDER_ID, "title": "Work", "isGroup": True, "position": 199,
         "isFolderCollapsed": True, "folderIcon": None,
         "workspace": SPACE_ID, "folderParentId": None},
        {"id": "22222222-2222-4222-8222-222222222222", "title": "Docs",
         "editedTitle": True, "url": "https://docs.example/",
         "position": 300, "isEssential": False, "workspace": SPACE_ID,
         "container": None, "folderParentId": FOLDER_ID},
    ]


def test_bad_session():
    with tempfile.TemporaryDirectory() as d:
        make_profile(d).close()
        with open(os.path.join(d, "zen-sessions.jsonlz4"), "wb") as f:
            f.write(b"garbage")
        r = run(d, os.path.join(d, "out.json"))
        assert r.returncode != 0
        assert "not a mozLz4 file" in r.stderr


if __name__ == "__main__":
    test_export()
    test_bad_session()
    print("ok")
```

- [ ] **Step 2: Run the test to check it fails**

Run: `eval "$PYLZ4" home/programs/zen/zen-export-test.py`
Expected: FAIL, `AssertionError` from `r.returncode == 0` with "can't open
file ... zen-export.py" in stderr.

- [ ] **Step 3: Write the export script**

`home/programs/zen/zen-export.py`:

```python
import json
import os
import shutil
import sqlite3
import sys
import tempfile
import uuid

import lz4.block


def norm_id(raw):
    s = raw.strip("{}")
    try:
        return str(uuid.UUID(s))
    except ValueError:
        # Folder ids are "<ms>-<n>", not UUIDs.
        return str(uuid.uuid5(uuid.NAMESPACE_URL, "zen:" + s))


def read_bookmarks(places):
    if not os.path.exists(places):
        sys.exit(f"{places}: not found")
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
                out.append({"name": title or url, "url": url})
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


def entry_of(tab):
    initial = (tab.get("_zenPinnedInitialState") or {}).get("entry")
    if initial:
        return initial
    entries = tab.get("entries") or [{}]
    return entries[min(tab.get("index", 1), len(entries)) - 1]


def read_session(path):
    if not os.path.exists(path):
        sys.exit(f"{path}: not found")
    with open(path, "rb") as f:
        raw = f.read()
    if raw[:8] != b"mozLz40\0":
        sys.exit(f"{path}: not a mozLz4 file")
    data = json.loads(lz4.block.decompress(raw[8:]))

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
    print(f"source: {len(pinned)} pinned tabs, {skipped} placeholders, {len(folders)} folders")
    return spaces, pins


def count_bookmarks(entries):
    return sum(count_bookmarks(e["bookmarks"]) if "bookmarks" in e else 1 for e in entries)


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: zen-export <profile-dir> <out.json>")
    profile, out = sys.argv[1:]
    bookmarks = read_bookmarks(os.path.join(profile, "places.sqlite"))
    spaces, pins = read_session(os.path.join(profile, "zen-sessions.jsonlz4"))
    with open(out, "w") as f:
        json.dump({"bookmarks": bookmarks, "pins": pins, "spaces": spaces},
                  f, indent=2, sort_keys=True, ensure_ascii=False)
        f.write("\n")
    tabs = [p for p in pins if not p.get("isGroup")]
    print(f"wrote: {count_bookmarks(bookmarks)} bookmarks, {len(tabs)} pins"
          f" ({sum(p['isEssential'] for p in tabs)} essentials),"
          f" {len(pins) - len(tabs)} folders")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run the test to check it passes**

Run: `eval "$PYLZ4" home/programs/zen/zen-export-test.py`
Expected: `ok`

- [ ] **Step 5: Commit**

```bash
git add home/programs/zen/zen-export.py home/programs/zen/zen-export-test.py
git commit -m "feat(zen): add profile export script"
```

---

### Task 2: Zen module with Personal and Professional

**Files:**
- Modify: `flake.nix` (inputs block near line 10; `overlays` list near line 58)
- Create: `home/programs/zen/lib.nix`
- Create: `home/programs/zen/default.nix`
- Create: `home/programs/zen/profiles/personal.json`
- Create: `home/programs/zen/profiles/professional.json`
- Modify: `home/users/matt/common.nix:195` (remove the zen package) and the
  `imports` list near line 517
- Modify: `home/programs/stylix.nix:59`

**Interfaces:**
- Consumes: `zen-export.py` from Task 1 (packaged here).
- Produces: `import ./lib.nix pkgs` returns `{ extensions = { shared;
  personal; work; }; mkProfile = { id, path, file, extensions }: <profile
  attrs>; }`. Task 4 uses both.

- [ ] **Step 1: Add the firefox-addons input and overlay**

In `flake.nix`, after the `zen-browser` input lines, add:

```nix
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

In the `overlays` list, after `inputs.claude-code.overlays.default`, add:

```nix
        # The flake's own packages use a nixpkgs that rejects unfree 1Password.
        inputs.firefox-addons.overlays.default
```

Run: `nix flake lock`
Expected: `flake.lock` gains a `firefox-addons` node.

- [ ] **Step 2: Write `lib.nix`**

`home/programs/zen/lib.nix`:

```nix
pkgs:
let
  addons = pkgs.firefox-addons;
  # Not packaged in rycee firefox-addons.
  no-youtube-shorts = addons.buildFirefoxXpiAddon {
    pname = "no-youtube-shorts";
    version = "3.1.4";
    addonId = "{4590d8b8-3569-46e3-a571-cabfbaeab2c1}";
    url = "https://addons.mozilla.org/firefox/downloads/file/4590220/no_youtube_shorts-3.1.4.xpi";
    sha256 = "c598c7ffe2779a1f1865d0335652f7096991fe24f3c460abf90a11e8c65ad8fd";
    meta = { };
  };
in
{
  extensions = {
    shared = with addons; [
      ublock-origin
      darkreader
      vimium
      no-youtube-shorts
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

  mkProfile =
    {
      id,
      path,
      file,
      extensions,
    }:
    let
      data = builtins.fromJSON (builtins.readFile file);
      byId = list: builtins.listToAttrs (map (x: { name = x.id; value = x; }) list);
    in
    {
      inherit id path;
      extensions.packages = extensions;
      bookmarks = {
        force = true;
        settings = data.bookmarks;
      };
      spaces = byId data.spaces;
      pins = byId data.pins;
      mods = [
        "58649066-2b6f-4a5b-af6d-c3d21d16fc00" # Private Mode Highlighting
        "a6335949-4465-4b71-926c-4a52d34bc9c0" # Better Find Bar
        "c6813222-6571-4ba6-8faf-58f3343324f6" # Disable Rounded Corners
      ];
      settings = {
        # Profile-scoped extensions start disabled without this.
        "extensions.autoDisableScopes" = 0;
        # Zen re-imports declared bookmarks on each start; Sync would push
        # that reset to every other device.
        "services.sync.engine.bookmarks" = false;

        "browser.newtabpage.enabled" = false;
        "browser.startup.homepage" = "chrome://browser/content/blanktab.html";
        "browser.startup.page" = 1;
        "browser.tabs.hoverPreview.showThumbnails" = false;
        "browser.toolbars.bookmarks.showOtherBookmarks" = false;
        "browser.toolbars.bookmarks.visibility" = "newtab";
        "browser.urlbar.quicksuggest.dataCollection.enabled" = false;
        "layout.css.prefers-color-scheme.content-override" = 0;
        "sidebar.visibility" = "hide-launcher";
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "zen.glance.enabled" = false;
        "zen.pinned-tab-manager.restore-pinned-tabs-to-pinned-url" = true;
        "zen.site-data-panel.show-callout" = false;
        "zen.tab-unloader.enabled" = false;
        "zen.tabs.close-on-back-with-no-history" = false;
        "zen.tabs.dim-pending" = false;
        "zen.tabs.select-recently-used-on-close" = false;
        "zen.theme.accent-color" = "#a0d490";
        "zen.theme.color-prefs.colorful" = true;
        "zen.theme.color-prefs.use-workspace-colors" = false;
        "zen.urlbar.behavior" = "normal";
        "zen.urlbar.replace-newtab" = false;
        "zen.view.compact.enable-at-startup" = true;
        "zen.view.compact.should-enable-at-startup" = true;
        "zen.view.show-bottom-border" = true;
        "zen.view.show-newtab-button-top" = false;
        "zen.view.sidebar-expanded.on-hover" = false;
        "zen.view.split-view.change-on-hover" = false;
        "zen.view.use-single-toolbar" = false;
        "zen.view.window.scheme" = 0;
        "zen.welcome-screen.seen" = true;
      };
    };
}
```

- [ ] **Step 3: Write `default.nix` and empty data files**

`home/programs/zen/default.nix`:

```nix
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  zen = import ./lib.nix pkgs;
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  home.packages = [
    (pkgs.writers.writePython3Bin "zen-export" {
      libraries = [ pkgs.python3Packages.lz4 ];
      flakeIgnore = [ "E501" ];
    } (builtins.readFile ./zen-export.py))
  ];

  programs.zen-browser = {
    enable = true;
    profiles = {
      Personal =
        zen.mkProfile {
          id = 0;
          path = "personal";
          file = ./profiles/personal.json;
          extensions = zen.extensions.shared ++ zen.extensions.personal;
        }
        // {
          isDefault = lib.mkDefault true;
        };
      Professional = zen.mkProfile {
        id = 1;
        path = "professional";
        file = ./profiles/professional.json;
        extensions = zen.extensions.shared ++ zen.extensions.personal;
      };
    };
  };
}
```

Write both `profiles/personal.json` and `profiles/professional.json` as:

```json
{
  "bookmarks": [],
  "pins": [],
  "spaces": []
}
```

- [ ] **Step 4: Wire it into `common.nix` and Stylix**

In `home/users/matt/common.nix`, delete this line from `home.packages`:

```nix
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Add `../../programs/zen` to the `imports` list next to
`../../programs/stylix.nix`.

In `home/programs/stylix.nix`, change line 59 to:

```nix
      zen-browser.profileNames = [
        "Personal"
        "Professional"
      ];
```

- [ ] **Step 5: Build Karsa and Kruppe**

```bash
git add home/programs/zen flake.nix flake.lock
hmbuild karsa && hmbuild kruppe
```

Expected: both print a store path. If `zen-export` fails flake8, fix the
reported line in `zen-export.py` and rerun Task 1's test.

- [ ] **Step 6: Check warnings, user.js and the desktop file**

```bash
nix eval --json .#nixosConfigurations.karsa.config.home-manager.users.matt.warnings
nix eval --raw .#nixosConfigurations.karsa.config.home-manager.users.matt.home.file --apply 'f: builtins.concatStringsSep "\n" (builtins.attrNames f)' | grep 'zen/.*user.js'
hp=$(nix build --no-link --print-out-paths .#nixosConfigurations.karsa.config.home-manager.users.matt.home.path)
ls "$hp/share/applications" | grep zen; ls "$hp/bin" | grep -E 'zen'
```

Expected:
- the warnings list has no `[Zen Browser]` entries
- the file list includes paths ending in `zen/personal/user.js` and
  `zen/professional/user.js`
- `zen-beta.desktop` exists, matching the `mimeApps` entries in `common.nix`
- `zen-export` is in `bin`

Then check the Sync setting reached `user.js`:

```bash
nix eval --raw .#nixosConfigurations.karsa.config.home-manager.users.matt.home.file --apply 'f: let n = builtins.head (builtins.filter (n: builtins.match ".*zen/personal/user.js" n != null) (builtins.attrNames f)); in f.${n}.text' | grep -E 'sync.engine.bookmarks|autoDisableScopes'
```

Expected: both prefs, set to `false` and `0`.

- [ ] **Step 7: Commit**

```bash
git add flake.nix flake.lock home/programs/zen home/users/matt/common.nix home/programs/stylix.nix
git commit -m "feat(zen): declare Personal and Professional profiles"
```

---

### Task 3: Export Karsa profiles

**Files:**
- Modify: `home/programs/zen/profiles/personal.json`
- Modify: `home/programs/zen/profiles/professional.json`

**Interfaces:**
- Consumes: `zen-export.py` (Task 1); the JSON shape that `mkProfile`
  (Task 2) reads.

- [ ] **Step 1: Export**

```bash
eval "$PYLZ4" home/programs/zen/zen-export.py ~/.zen/ypxjh9wx.default home/programs/zen/profiles/personal.json
eval "$PYLZ4" home/programs/zen/zen-export.py "$HOME/.zen/7vXcv4kc.Profile 2" home/programs/zen/profiles/professional.json
```

Expected:
- Personal prints `source: 4 pinned tabs, 0 placeholders, 0 folders` and
  writes 4 pins (4 essentials).
- Professional prints `source: 7 pinned tabs, 0 placeholders, 0 folders` and
  writes 7 pins (5 essentials).
- Bookmarks: at most 43 for Personal and 12 for Professional. Those raw counts
  include tag entries and `place:` queries, which the export skips.

If a pin count differs, stop and report the counts to the user.

- [ ] **Step 2: User review for sensitive content**

Show the user `git diff --stat` and the URL list:

```bash
jq -r '.. | .url? // empty' home/programs/zen/profiles/personal.json home/programs/zen/profiles/professional.json | sort -u
```

Ask the user to approve or name entries to remove. Delete the named entries
from the JSON by hand. Do not continue without approval.

- [ ] **Step 3: Build**

```bash
hmbuild karsa
```

Expected: a store path. A type error naming a pin or bookmark field means the
JSON does not match the flake options. Fix the export script, add a failing
case to `zen-export-test.py`, and rerun Task 1's test and this task.

- [ ] **Step 4: Commit**

```bash
git add home/programs/zen/profiles
git commit -m "feat(zen): seed Personal and Professional from Karsa"
```

---

### Task 4: Work profile

**Files:**
- Create: `home/programs/zen/work.nix`
- Create: `home/programs/zen/profiles/work.json`
- Modify: `home/users/matt/common-work.nix` (`imports` list near line 9)

**Interfaces:**
- Consumes: `lib.nix` `extensions` and `mkProfile` (Task 2).

- [ ] **Step 1: Write `work.nix` and an empty `work.json`**

`home/programs/zen/work.nix`:

```nix
{ pkgs, ... }:
let
  zen = import ./lib.nix pkgs;
in
{
  programs.zen-browser.profiles = {
    Personal.isDefault = false;
    Work =
      zen.mkProfile {
        id = 2;
        path = "work";
        file = ./profiles/work.json;
        extensions = zen.extensions.shared ++ zen.extensions.work;
      }
      // {
        isDefault = true;
      };
  };

  stylix.targets.zen-browser.profileNames = [ "Work" ];
}
```

`home/programs/zen/profiles/work.json`:

```json
{
  "bookmarks": [],
  "pins": [],
  "spaces": []
}
```

- [ ] **Step 2: Import it on work hosts**

In `home/users/matt/common-work.nix`, add `../../programs/zen/work.nix` to the
`imports` list.

- [ ] **Step 3: Build Tehol, Samar and Karsa**

```bash
git add home/programs/zen
hmbuild tehol && hmbuild samar && hmbuild karsa
```

Expected: 3 store paths.

- [ ] **Step 4: Check the Work extension split**

```bash
nix eval --json .#nixosConfigurations.tehol.config.home-manager.users.matt.programs.zen-browser.profiles --apply 'ps: builtins.mapAttrs (_: p: { default = p.isDefault; ext = map (e: e.pname) p.extensions.packages; }) ps'
```

Expected:
- Work has `default = true`; its extensions include
  `onepassword-password-manager` and no `bitwarden`, `leechblock-ng`, `7tv`,
  `betterttv` or `toolkit-for-ynab`.
- Personal has `default = false` and includes `bitwarden`.

- [ ] **Step 5: Commit**

```bash
git add home/programs/zen home/users/matt/common-work.nix
git commit -m "feat(zen): add default Work profile on work hosts"
```

---

### Task 5: Export the Tehol work profile

**Superseded.** The user reviewed the export and decided Work pins, essentials
and bookmarks stay imperative. `mkProfile` takes an optional `file`; Work has
none, so it declares no bookmarks, spaces or pins. Task 7 copies the session
file instead.

**Files:**
- Modify: `home/programs/zen/profiles/work.json`

**Interfaces:**
- Consumes: `zen-export.py` (Task 1).

- [ ] **Step 1: Export over SSH**

```bash
scp home/programs/zen/zen-export.py tehol:/tmp/zen-export.py
ssh tehol 'cd ~/.config/zen && nix shell --impure --expr "with import <nixpkgs> {}; python3.withPackages (p: [p.lz4])" -c python3 -I /tmp/zen-export.py "5l6d3a2k.Default Profile" /tmp/work.json'
scp tehol:/tmp/work.json home/programs/zen/profiles/work.json
ssh tehol 'rm /tmp/zen-export.py /tmp/work.json'
```

Expected: `source: 40 pinned tabs, 1 placeholders, 1 folders` and `wrote:
<n> bookmarks, 39 pins (9 essentials), 1 folders`. If these differ, stop and
report the counts to the user. Do not continue.

- [ ] **Step 2: User review for sensitive content**

```bash
jq -r '.. | .url? // empty' home/programs/zen/profiles/work.json | sort -u
```

Show the list to the user. Ask them to approve or name entries to remove.
Delete the named entries by hand. Do not continue without approval.

- [ ] **Step 3: Build Tehol and Samar**

```bash
hmbuild tehol && hmbuild samar
```

Expected: 2 store paths.

- [ ] **Step 4: Commit**

```bash
git add home/programs/zen/profiles/work.json
git commit -m "feat(zen): seed Work profile from Tehol"
```

---

### Task 6: Karsa cutover (user at Karsa)

**Files:** none.

The user must be at Karsa. Run each command only after the user confirms the
previous step.

- [ ] **Step 1: Back up and switch**

Ask the user to close Zen fully. Then:

```bash
pgrep -af zen | grep -v zen-export || echo "zen closed"
mv ~/.zen ~/.zen.bak
hmswitch
```

Expected: `zen closed`, then a successful activation. "Sessions file not
found" lines are expected on the first switch.

- [ ] **Step 2: First run and second switch**

Ask the user to open Zen, open each profile once from the profile picker,
then close Zen fully. Then:

```bash
hmswitch 2>&1 | tee /tmp/hmswitch.log
grep -i 'skipped' /tmp/hmswitch.log || echo "pins applied"
```

Expected: `pins applied`. If you see "skipped", Zen is still running. Ask the
user to close it and run this step again.

- [ ] **Step 3: Remove the auto-created space**

On first run Zen creates an empty space named "Space" with a random ID; the
declared space is added beside it. Ask the user, in each of Personal and
Professional, to switch to the declared space (Personal: "Personal";
Professional: the "Space" that holds the essentials) and delete the other,
empty one.

- [ ] **Step 4: User checks each profile**

Ask the user to confirm in Personal and in Professional:
- essentials and pins match the old profile
- bookmarks are on the toolbar and in the menu
- extensions are present and enabled; mods are active
- Firefox Sync sign-in works, with the bookmarks engine off

Rollback, if needed:

```bash
ls -d ~/.local/state/nix/profiles/home-manager-*-link | tail -2
# run "<previous>/activate", then:
mv ~/.config/zen ~/.config/zen.new && mv ~/.zen.bak ~/.zen
```

---

### Task 7: Tehol cutover (user at Tehol)

**Files:** none.

Run on Tehol after `git pull`. Run each command only after the user confirms
the previous step.

- [ ] **Step 1: Back up, switch and carry the Work session over**

Ask the user to close Zen fully. Then:

```bash
pgrep -af zen | grep -v zen-export || echo "zen closed"
cp -a ~/.config/zen ~/.config/zen.bak
hmswitch
old=~/.config/zen.bak/"5l6d3a2k.Default Profile"
cp "$old"/zen-sessions.jsonlz4 "$old"/places.sqlite ~/.config/zen/work/
```

Expected: `zen closed`, then a successful activation. The copy must happen
before Work first opens, or Zen writes a fresh session over it.
`places.sqlite` carries the Work bookmarks; Work declares none.

- [ ] **Step 2: First run and second switch**

Ask the user to open each profile once, then close Zen fully. Then:

```bash
hmswitch 2>&1 | tee /tmp/hmswitch.log
grep -i 'skipped' /tmp/hmswitch.log || echo "pins applied"
```

Expected: `pins applied`.

- [ ] **Step 3: Remove the auto-created space**

On first run Zen creates an empty space named "Space" with a random ID; the
declared space is added beside it. Ask the user, in each of Personal and
Professional, to switch to the declared space (Personal: "Personal";
Professional: the "Space" that holds the essentials) and delete the other,
empty one.

- [ ] **Step 4: User checks Work**

Ask the user to confirm in Work:
- 39 pins, including 9 essentials and the folder, match the old "Default
  Profile"
- 1Password is present and Bitwarden is absent
- Work opens by default
- Sync is signed in with the Countersight account

Tell the user that the old "Default Profile" and "personal" folders remain in
`~/.config/zen` but no longer show in the profile picker.

Rollback, if needed: run the previous generation's `activate` (from
`ls -d ~/.local/state/nix/profiles/home-manager-*-link | tail -2`), then
`mv ~/.config/zen ~/.config/zen.new && mv ~/.config/zen.bak ~/.config/zen`.
