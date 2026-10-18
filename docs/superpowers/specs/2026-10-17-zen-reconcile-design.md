# Zen reconcile tool design

## Goal

`zen-reconcile` shows how each live Zen profile differs from the Nix config,
one difference per row. For each row the user can promote the live state into
the repo, revert the browser to the config, skip it, or ignore it for good.

Scope: bookmarks, pins (with essentials, pin folders and spaces), toolbar
layout, settings and keyboard shortcuts, for every declared profile. Work gets
the same treatment; the user decides item by item what is safe to commit to the
public repo.

## Architecture

```
home/programs/zen/
  zen_profile.py        library: read live, read config, diff, apply
  zen-export.py         thin CLI over zen_profile; behaviour unchanged
  zen-reconcile.py      Textual TUI over zen_profile
  tests/                fixture profiles, library tests, Textual pilot tests
  profiles/<name>.json  bookmarks, pins, spaces; work.json created on demand
  settings/shared.json  settings for every profile
  settings/<name>.json  per-profile settings
  settings/ignore.json  dismissed identities, per kind
  shortcuts/shared.json, shortcuts/<name>.json
  toolbar.json, toolbar-work.json, toolbar-<name>.json on demand
```

Nix packages both commands with `python3.withPackages [ lz4 textual ]`, like
`zen-export` today, and passes `--repo` and `--active` to `zen-reconcile`.

### Source of truth

- Config: the activated generation's zen JSON, linked at
  `~/.config/zen-reconcile/active`. Differences are live against that.
- Writes: promote and ignore edit the checkout (`--repo`, passed from Nix as
  `~/nixos-config`). A row the checkout already resolves shows as "pending
  switch" until the next switch. Without a checkout the tool is read-only:
  reverts still work.
- Settings declared outside the JSON (Betterfox, Stylix, the flake, the Nix
  settings in `lib.nix`): read from the profile's generated `user.js`.
  Promoting one writes an override into the JSON; presets are never edited.
- Profiles: discovered from `profiles.ini`. A profile name maps to
  `profiles/<lowercased name>.json` and `settings/<lowercased name>.json`.

### Refactor of lib.nix

- Plain settings move to `settings/shared.json`; Work's download and form data
  settings move to `settings/work.json`.
- Settings that need a comment or a computed value stay in Nix:
  `extensions.autoDisableScopes`, `services.sync.engine.bookmarks`,
  `browser.uiCustomization.state` and `browser.download.dir`.
- The custom shortcuts move to `shortcuts/shared.json`.
- `lib.nix` merges Nix settings, then `shared.json`, then `<name>.json`. JSON
  values use `lib.mkOverride 90`, so a promoted override of a Stylix or
  Betterfox setting wins without a definition conflict.
- `mkProfile` reads the toolbar from `toolbar-<name>.json` when it exists, then
  the profile's `toolbar` argument, then `toolbar.json`.

## Differences and actions

Keys: `p` promote, `r` revert, `s` skip, `i` ignore. Ignore adds the identity
to `settings/ignore.json` under its kind.

| Kind | Identity | Shown when | Promote writes | Revert |
|---|---|---|---|---|
| Bookmark | folder path + URL | added, removed, renamed, moved, folder reordered | `profiles/<name>.json` | next Zen start; Zen re-imports declared bookmarks |
| Pin, essential, folder, space | pin or space ID | live only, config only, title, URL, essential, folder or position changed | `profiles/<name>.json` | live only: removed from `zen-sessions.jsonlz4` (Zen closed); others: next switch, the flake re-applies them |
| Toolbar | area name | area contents or order differ | the profile's toolbar file, or a new `toolbar-<name>.json` when the shared layout should not change | next Zen start; `user.js` re-applies it |
| Setting | pref name | live value differs from the declared value, or an undeclared pref is set | `settings/shared.json` or `settings/<name>.json` | declared: next Zen start; undeclared: line removed from `prefs.js` (Zen closed) |
| Shortcut | shortcut ID | differs from the baseline | `shortcuts/shared.json` or `shortcuts/<name>.json` | entry restored in `zen-keyboard-shortcuts.json` (Zen closed) |

`t` toggles the promote target between all profiles and this profile, for
settings, shortcuts and toolbar.

Pin identities use the export's ID rules: braces stripped, folder IDs mapped to
UUID v5, folder placeholder tabs skipped.

### Shortcut baseline

Zen's shortcut file holds every shortcut, with no record of which ones the user
changed. After the flake applies the declared shortcuts, an activation step
writes `zen-shortcuts-baseline.json` into the profile when it is missing or when
`zen.keyboard.shortcuts.version` differs from the one it records. Live entries
that differ from the baseline are shown. Promote and revert update the
baseline. Shortcuts a Zen update adds are absent from the baseline and never
shown.

### Zen open or closed

The tool reads at any time. Promotes and restart-only reverts apply at any
time. Reverts that edit `prefs.js`, `zen-sessions.jsonlz4` or
`zen-keyboard-shortcuts.json` apply only when the profile's `.parentlock` is
free; Zen rewrites those files from memory, so an edit under a running Zen is
lost. Otherwise the row stays queued with "close Zen to apply".

Before editing a Zen file the tool copies it to `*.pre-reconcile`.

## TUI

- Header: profile name, Zen open or closed; a key cycles profiles.
- List of differences grouped by kind, with a filter per kind.
- Detail pane: live against config. Bookmarks and pins show title, URL and
  folder; toolbars show both area lists.
- Marked rows show their pending action. `a` asks for confirmation, applies,
  then lists the repo files written and any queued reverts, and suggests
  `git diff`, a commit and `nixswitch`. The tool never commits or switches.

## Errors

- An unparseable repo JSON file: shown, and nothing is written.
- A profile without a data file: config treated as empty, so every live pin
  shows as live only.
- A missing live file (a profile never opened): that kind is skipped with a
  note.

## Testing

- Library tests on fixture profiles built in a temp folder: places, session,
  `prefs.js`, `user.js`, shortcuts and baseline. One case per kind and action,
  plus revert queueing while `.parentlock` is held.
- Textual pilot tests: keys mark rows; apply calls the library.
- Nix: building Karsa and Tehol evaluates the JSON merge; a check confirms a
  JSON override of a Stylix setting builds without a conflict.
- Manual: change one item of each kind in Zen, run `zen-reconcile`, promote
  some and revert others, then confirm after a restart and a switch.

## Out of scope

- Extensions, mods, search engines and containers.
- Committing, pushing or switching.
