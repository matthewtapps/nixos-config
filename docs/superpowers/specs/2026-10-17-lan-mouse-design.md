# Lan Mouse design

## Goal

One keyboard and mouse control any of Karsa, Kruppe, Samar, Mappo and Tehol
through Lan Mouse over Tailscale. The Noctalia bar arranges the hosts by drag
and drop, turns each one on or off, and shows which are online. Alt+U switches
to a peer and back without using an edge.

## Constraints

- Lan Mouse 0.11.0 from nixpkgs. The flake input built from source on every
  update.
- Capture uses `layer-shell`. `xdg-desktop-portal-hyprland` 1.4.1 advertises
  `InputCapture`, so Lan Mouse picks the portal first, and on Hyprland that
  backend misfires at edges and dies with `Portal request didn't succeed`.
- Lan Mouse models a peer as a whole device on one side: left, right, top or
  bottom. There are no corners and no edge offsets.
- A cursor only returns if the receiver has the sender as a client on the
  opposite side (`src/capture.rs`, `EnterOnly` handling). Both ends of a pair
  must agree.
- Lan Mouse rewrites `config.toml` on every runtime change. A Home Manager
  file is read-only, so the write fails and is only logged
  (`src/service.rs:241`). Runtime changes live until the daemon restarts.
- While Karsa captures input, Hyprland on Karsa sees no keys. Only the Lan
  Mouse release keybind works from a peer.

## Layout

```
nixos/modules/lan-mouse.nix          sops certificate; imported by wayland.nix
home/programs/lan-mouse.nix          config.toml, daemon, layoutd, push script
home/programs/lan-mouse-push.sh      Alt+U script
home/programs/noctalia/plugins/lan-mouse/
  plugin.toml
  layout.luau                        pure layout logic
  layout-test.luau                   self-check, run with luau
  service.luau                       reconcile loop, monitor publishing
  bar.luau                           bar glyph
  panel.luau                         drag and drop panel
secrets/lan-mouse/<host>.pem         one certificate per host
```

- `home/users/matt/common.nix` imports `lan-mouse.nix`. The module applies only
  when `device` is one of the 5 hosts, so Baruk is unaffected.
- `home/programs/noctalia/default.nix` links the plugin like `taildrop`, and
  each profile lists it under `[plugins] enabled`.
- `home/programs/hypr/hyprland/common.lua` binds `ALT + u` to `lan-mouse-push`.
- The keybind cheatsheet gains Alt+U.

## Certificates

Lan Mouse certificates are self-signed and valid until the year 4096, so they
never change.

- Each host gets `secrets/lan-mouse/<host>.pem`, encrypted to that host and
  `matt`. `.sops.yaml` gains one creation rule per host.
- `sops.secrets.lan-mouse-cert` uses `format = "binary"`, `owner = "matt"` and
  mode `0400`. `config.toml` sets `cert_path` to its path. The file always
  exists, so Lan Mouse never generates one.
- Karsa and Tehol keep their current certificates. The other 3 are generated
  on Karsa with `lan-mouse --cert-path <file> daemon`.
- Fingerprints are public and live in `lan-mouse.nix` as a host map. Each
  host's `authorized_fingerprints` lists every other host.

## config.toml

```toml
port = 4242
release_bind = ["KeyLeftAlt", "KeyU"]
capture_backend = "layer-shell"
cert_path = "/run/secrets/lan-mouse-cert"

[authorized_fingerprints]
"<fingerprint>" = "<host>"
```

No `[[clients]]`: the plugin creates them at runtime. A systemd user service
runs `lan-mouse daemon`, wanted by `hyprland-session.target`.

## Layout document

A second `taildrop-syncd` unit, `lan-mouse-layoutd`, runs with
`TAILDROP_SYNCD_PORT=8472`. The state folder includes the port, so it does not
clash with Taildrop. The document text is this JSON:

```json
{
  "enabled": { "karsa": true, "tehol": true, "mappo": false },
  "links": [{ "host": "karsa", "peer": "tehol", "side": "right" }],
  "monitors": {
    "karsa": [{ "name": "DP-1", "x": 0, "y": 0, "w": 2560, "h": 1440 }]
  }
}
```

- A link names a pair once. `karsa -> tehol: right` puts Karsa on Tehol's
  left. A pair has at most one link.
- `enabled` is per device and applies on every host. A disabled device keeps
  its links in the document; they are hidden and not applied.
- `monitors` holds logical sizes (pixels divided by scale). Only the host that
  owns an entry writes it.
- A missing host in `enabled` counts as enabled. An empty document places
  nothing.
- Last writer wins for the whole document. `taildrop-syncd` keeps the last 10
  versions, which `/restore` can bring back.

## Plugin service

Every 5 seconds, and on each document event:

1. Work out this host's view: for each enabled peer, the side relative to
   this host, or none.
2. Read `lan-mouse cli list` and send the commands that make it match the
   view: `add-client`, `remove-client`, `set-position`, `set-ips`,
   `activate`, `deactivate`. The plugin owns every client and removes any
   client it did not create.
3. Set each client's hostname to the peer name and its `ips` to the
   Tailscale address from `layoutd`'s `/health`.
4. Give each client an enter hook that writes the peer name to
   `$XDG_RUNTIME_DIR/lan-mouse/last`.
5. Compare `hyprctl monitors -j` with this host's `monitors` entry, and post
   the document when they differ.

When this host is disabled, every client is deactivated.

`layout.luau` holds steps 1 and 2 and the drop logic as pure functions.
`layout-test.luau` checks them with `luau` from nixpkgs. If Noctalia cannot
load a sibling module, the plugin carries the functions inline and the test
loads that file.

## Panel

```
 Lan Mouse                                            [on]
 +------------------------------------------------------+
 |                     [ drop: top ]                    |
 |                                                      |
 |  +----------+   +------------+--------+   +-------+  |
 |  | tehol  o |   |   DP-1     |  DP-2  |   | drop: |  |
 |  | [==][=]  |   |      karsa (this)   |   | right |  |
 |  +----------+   +------------+--------+   +-------+  |
 |                                                      |
 |                    [ drop: bottom ]                  |
 +------------------------------------------------------+
  Unplaced:  [ mappo o ]  [ kruppe x ]  [ samar o ]
```

- The centre draws this host's monitors to scale from its `monitors` entry.
  Each peer tile draws that peer's last published monitors.
- Each side is a `ui.dropZone`. Peer tiles are `ui.dragSource` with the peer
  name as payload.
- Dropping on an occupied side swaps the 2 peers. Dropping on Unplaced
  removes the link.
- Each tile has an on/off toggle. A disabled tile sits greyed out in Unplaced
  and cannot be dragged.
- The header switch sets `enabled` for this host.
- Online state comes from `/health`: `o` online, `x` offline. Offline peers
  can be moved; they pick up the change on reconnect.
- The bar glyph dims when this host is disabled and shows an error state when
  `lan-mouse cli` fails.

## Alt+U

On a host with input, `ALT + u` runs `lan-mouse-push`:

1. Pick the target: the peer in `$XDG_RUNTIME_DIR/lan-mouse/last` if it is
   still placed and online, else the first online placed peer checked
   right, bottom, left, top.
2. Find the outer edge of this host's monitors on the target's side, using
   `hyprctl monitors -j`.
3. Warp the cursor to the middle of that edge with `hyprctl dispatch
   movecursor`, then 1 pixel past it.

With no target, it sends a notification and does nothing.

On a peer, Alt+U matches `release_bind` on the capturing host, which releases
the cursor. Hyprland on the peer never receives it.

## Failure handling

- `layoutd` unreachable: the panel shows the layout as unavailable and
  disables editing. Lan Mouse keeps its clients.
- `lan-mouse cli` fails: the bar shows the error state and the next tick
  retries. A restarted daemon gets its clients back on the next tick.
- Peer offline: its client stays and does nothing.
- Lost monitor write: the next tick sees the difference and writes again.

## Testing

1. Before building Alt+U, confirm on Karsa that a `movecursor` warp onto the
   edge, plus a 1 pixel nudge, triggers the `layer-shell` capture. If it does
   not, stop and revisit Alt+U.
2. `luau layout-test.luau` passes.
3. All 5 host configurations build.
4. On Karsa and Tehol: place Tehol by drag, cross both ways by edge, Alt+U
   over and back, restart the daemon and see the clients return, disable and
   enable Tehol.
5. Move Mappo while it is offline, bring it online, and check it applies the
   change.
