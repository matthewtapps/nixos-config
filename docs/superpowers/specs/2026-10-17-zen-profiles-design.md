# Declarative Zen profiles design

## Goal

Every device gets the same Zen profiles from this repo. A new device needs
only a sign-in to each Firefox account and the site logins.

| Profile | Account | Hosts | Default |
|---|---|---|---|
| Personal | matt.tapps@gmail.com | all | personal hosts |
| Professional | mail@matthewtapps.com | all | no |
| Work | matthew.tapps@countersight.co | Tehol, Samar | work hosts |

Manual edits must keep working, because the Work config changes often. A
later reconcile tool (separate spec) promotes or reverts local drift.

## Layout

```
home/programs/zen/
  default.nix          shared extensions, mods, settings; Personal, Professional
  work.nix             Work profile, imported by common-work.nix
  data.nix             maps a profile JSON file onto flake options
  profiles/
    personal.json      exported from Karsa ypxjh9wx.default
    professional.json  exported from Karsa "7vXcv4kc.Profile 2"
    work.json          exported on Tehol
  zen-export.py        export script
  zen-export-test.py   self-check
```

- `common.nix` imports `zen/`, replacing the bare `zen-browser` package in
  `home.packages`.
- `common-work.nix` imports `zen/work.nix`, which adds Work and makes it the
  default profile.
- Profiles use fixed folder names (`personal`, `professional`, `work`) so they
  match on every device. On Karsa the new folders start empty. The old folders
  stay on disk but leave `profiles.ini`.
- Stylix `zen-browser.profileNames` gains Professional and Work.

## Shared config (hand-written Nix)

Extensions install through `policies.ExtensionSettings` with AMO
`install_url`s, so they track the latest release.

Shared set: uBlock Origin, Dark Reader, Vimium, Hover Zoom+, No YouTube
Shorts, Reddit Enhancement Suite, Add custom search engine, React DevTools,
Redux DevTools.

| Extension | Personal, Professional | Work |
|---|---|---|
| Bitwarden | yes | no |
| 1Password | no | yes |
| LeechBlock NG | yes | no |
| 7TV, BetterTTV | yes | no |
| Toolkit for YNAB | yes | no |

Colour-theme extensions are dropped; Stylix themes Zen.

Mods: Private Mode Highlighting, Better Find Bar, Disable Rounded Corners.

Settings: the user-changed `zen.*` and `browser.*` prefs from Karsa Personal,
for example `zen.view.compact.enable-at-startup`, `zen.glance.enabled`,
`zen.tab-unloader.enabled` and `zen.theme.accent-color`. Leave out
Zen-managed state: migration flags, milestones, active workspace IDs, the
sidebar state blobs and shortcut versions.

## Profile data (JSON)

Each `profiles/<name>.json` holds:

- `bookmarks`: the toolbar and menu trees with folders, names and URLs.
- `spaces`: name, ID, icon, position.
- `pins`: title, URL, ID (`zenSyncId`), space ID, essential flag, position.

`data.nix` reads it with `builtins.fromJSON` and sets `bookmarks` (with
`force = true`), `spaces` and `pins`. `spacesForce` and `pinsForce` stay
`false`, so manual spaces and pins survive. Declared bookmarks replace the
live set on each Zen start.

JSON keeps the files machine-rewritable for the reconcile tool.

## Export script

`zen-export <profile-dir> <name>` writes `profiles/<name>.json`.

- Packaged with `writers.writePython3Bin` and the `lz4` library.
- Copies `places.sqlite` and its `-wal` to a temp folder before reading,
  because Zen holds a lock on the live file.
- Reads bookmarks from `moz_bookmarks` and `moz_places`, skipping separators
  and the built-in "Mozilla" folders.
- Reads spaces and pins from `zen-sessions.jsonlz4` (`mozLz40` header, then
  an lz4 block).
- Keeps the existing IDs so merge mode matches declared pins to live tabs.
- Writes sorted, indented JSON so diffs stay small.

## Tehol handoff

1. Commit this spec and the implementation plan to `main`.
2. On Tehol, pull and run `zen-export` against the current work profile.
3. Review the `work.json` diff for sensitive content, then commit.

## Testing

- `zen-export-test.py` builds a tiny `places.sqlite` and session file, runs
  the export, and asserts the JSON output.
- Build the home configurations for Karsa and Tehol.
- After switching on Karsa, check that each profile opens with the expected
  bookmarks, essentials, extensions and mods.

## Out of scope

- The reconcile tool (diff, promote, revert); it gets its own spec.
- Logins, cookies and history; Firefox Sync and site logins cover these.
