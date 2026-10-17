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
  lib.nix              extension sets; maps a profile JSON file onto options
  profiles/
    personal.json      exported from Karsa ypxjh9wx.default
    professional.json  exported from Karsa "7vXcv4kc.Profile 2"
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

Extensions install per profile through `profiles.<name>.extensions.packages`.
Firefox policies apply to every profile, so they cannot keep Bitwarden out of
Work. Packages come from the rycee `firefox-addons` flake through its overlay,
which builds with this repo's `pkgs` and so allows unfree 1Password. No
YouTube Shorts is not in rycee; it is built with `buildFirefoxXpiAddon` from a
pinned AMO file.

Shared set: uBlock Origin, Dark Reader, Vimium, No YouTube Shorts, Reddit
Enhancement Suite, Add custom search engine, React DevTools, Redux DevTools.

| Extension | Personal, Professional | Work |
|---|---|---|
| Bitwarden | yes | no |
| 1Password | no | yes |
| LeechBlock NG | yes | no |
| 7TV, BetterTTV | yes | no |
| Toolkit for YNAB | yes | no |

Hover Zoom+ is dropped: AMO no longer serves it. Colour-theme extensions are
dropped; Stylix themes Zen.

Mods: Private Mode Highlighting, Better Find Bar, Disable Rounded Corners.

Settings: the user-changed `zen.*` and `browser.*` prefs from Karsa Personal,
for example `zen.view.compact.enable-at-startup`, `zen.glance.enabled`,
`zen.tab-unloader.enabled` and `zen.theme.accent-color`. Leave out
Zen-managed state: migration flags, milestones, active workspace IDs, the
sidebar state blobs and shortcut versions. Leave out `zen.workspaces.*` too:
Karsa disables workspaces but Tehol uses them, and Zen's defaults suit both.

## Toolbar and colours

- `toolbar.json` holds `browser.uiCustomization.state`, taken from the Karsa
  Personal layout, including the profile switcher. `user.js` re-applies it on
  every start, so toolbar edits in Zen are lost unless they are copied into the
  file. The reconcile tool covers this.
- The default profile on each host uses Stylix Everforest. Other profiles get
  the Stylix Zen CSS in another base16 scheme: Professional uses Tokyo Night
  Dark, and Personal on work hosts uses Gruvbox Dark Medium.

## Profile data (JSON)

Work has no data file. Its bookmarks, spaces and pins stay imperative,
because they map internal infrastructure that does not belong in a public
repo. A new work device copies `zen-sessions.jsonlz4` from an existing one.

Each `profiles/<name>.json` holds:

- `bookmarks`: the toolbar and menu trees with folders, names and URLs.
- `spaces`: name, ID, icon, position.
- `pins`: title, URL, ID (`zenSyncId`), space ID, essential flag, position,
  and parent folder ID. Pin folders are pins with `isGroup = true`.

`lib.nix` reads it with `builtins.fromJSON` and sets `bookmarks` (with
`force = true`), `spaces` and `pins`. `spacesForce` and `pinsForce` stay
`false`, so manual spaces and pins survive. Declared bookmarks replace the
live set on each Zen start.

JSON keeps the files machine-rewritable for the reconcile tool.

## Export script

`zen-export <profile-dir> <out.json>` writes one profile's JSON file.

- Packaged with `writers.writePython3Bin` and the `lz4` library.
- Copies `places.sqlite` and its `-wal` to a temp folder before reading,
  because Zen holds a lock on the live file.
- Reads bookmarks from `moz_bookmarks` and `moz_places`, skipping separators
  and `place:` queries. Toolbar items go in the toolbar folder, menu items at
  the top level, and unfiled items in an "Other Bookmarks" folder.
- Reads spaces and pins from `zen-sessions.jsonlz4` (`mozLz40` header, then
  an lz4 block).
- Strips the braces Zen wraps around IDs; the flake adds them back. Folder
  IDs are not UUIDs, so they map to a deterministic UUID v5.
- Skips the hidden placeholder tab Zen keeps in each folder (its `zenSyncId`
  is in the folder's `emptyTabIds`); the flake creates its own.
- Writes indented JSON with sorted keys so diffs stay small. List order is
  kept, because it is the bookmark and pin order.
- Prints the source counts (pinned tabs, placeholders, folders) and the
  written counts (bookmarks, pins, essentials, folders) for comparison.
- Never writes to the source profile.

## Cutover and safeguards

On Tehol, copy `zen-sessions.jsonlz4` and `places.sqlite` from the old
"Default Profile" into the new Work profile before Work first opens. It holds the 39 pins, 9 essentials
and one folder; the flake leaves it alone because Work declares no pins.

The flake writes profiles to `~/.config/zen`. Zen keeps using a legacy
`~/.zen` while it exists, so Karsa must move it aside.

On each host, before the first switch:

1. Export the source profiles and confirm the counts match the live session.
   Tehol "Default Profile" exports 39 pins (9 essentials) and one folder.
2. Back up the Zen folder: move `~/.zen` to `~/.zen.bak` on Karsa; copy
   `~/.config/zen` to `~/.config/zen.bak` on Tehol.
3. Close Zen and switch. Zen creates the session file on first run, so open
   each new profile once, close Zen, and switch again to apply the pins.
4. In each declared profile, delete the empty "Space" Zen created on first
   run; the declared space sits beside it.
5. Check each profile.

Old profile folders are never edited or deleted. Rolling back the
home-manager generation restores the old `profiles.ini`.

The Tehol work profile is signed
in to Sync as mail@matthewtapps.com; the new Work profile should use the
Countersight account.

## Testing

- `zen-export-test.py` builds a tiny `places.sqlite` and session file, runs
  the export, and asserts the JSON output.
- Build the home configurations for Karsa and Tehol.
- After switching on Karsa, check that each profile opens with the expected
  bookmarks, essentials, extensions and mods.

## Out of scope

- The reconcile tool (diff, promote, revert); it gets its own spec.
- Logins, cookies and history; Firefox Sync and site logins cover these.
