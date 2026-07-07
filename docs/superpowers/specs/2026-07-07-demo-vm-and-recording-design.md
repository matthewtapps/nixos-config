# Demo VM + Screen Recording — Design

**Date:** 2026-07-07
**Host:** tehol (work laptop; Hyprland/Wayland, Intel graphics)
**Goal:** (1) Spin up a clean Ubuntu VM to demo with, with easy file transfer from host. (2) Record screen + microphone into an editable demo video.

## Context

- tehol already has `kvm-intel` loaded (`nixos/hardware/tehol.nix`) — hardware virtualization ready.
- Hyprland PipeWire portal already configured (`nixos/modules/wayland.nix` → `xdg-desktop-portal-hyprland`) — OBS screen capture works via the portal, no extra setup.
- `wf-recorder` already present in `home/users/matt/common.nix` (kept; OBS is the fuller-fat addition, not a replacement).
- Idiom: per-program home modules under `home/programs/`, imported per-host in `home/users/matt/<host>.nix`. System modules under `nixos/modules/`, imported per-host in `nixos/hosts/<host>.nix`.
- `nixos/modules/virtualization.nix` handles docker/podman group membership via `lib.genAttrs` over `host.users` — pattern reference for group adds.

## Part 1 — Demo VM (quickemu)

**Decision:** quickemu (not libvirt/Boxes). Persistent disk with one-command throwaway reset via snapshots. SPICE display (local, lower latency than RDP) shows the full Ubuntu GNOME desktop + browser in a window.

**New system module:** `nixos/modules/demo-vm.nix`, imported in `nixos/hosts/tehol.nix`.

Responsibilities:
- Add `pkgs.quickemu` to system packages.
- Add `matt` to the `kvm` group for `/dev/kvm` access.
- Ship a `demo-vm` helper (`writeShellScriptBin`) wrapping the quickemu workflow so flags aren't memorized. Storage fixed at `~/VMs/`.

Helper subcommands:
- `demo-vm create` → `quickget ubuntu 24.04` into `~/VMs/`.
- `demo-vm start` → `quickemu` on the ubuntu conf with SPICE display + shared folder.
- `demo-vm snapshot` → `quickemu --snapshot create clean` (run after first install to mark pristine).
- `demo-vm reset` → `quickemu --snapshot restore clean` (throwaway back to pristine in seconds).

**Lifecycle:** persistent by default; `reset` restores the `clean` snapshot for a throwaway pristine state.

**File send host → VM** (SPICE agent, three ways):
- Shared folder — `~/VMs/<vm>/shared` auto-mounts in guest via spice-webdav.
- Drag-and-drop file into the SPICE window.
- Clipboard copy/paste both directions.

## Part 2 — Recording (OBS)

**New home module:** `home/programs/recording.nix`, imported in `home/users/matt/tehol.nix`.

- `programs.obs-studio.enable = true`.
- Plugin: `obs-pipewire-audio-capture` (clean mic + per-app audio on PipeWire).
- Screen capture via the existing Hyprland PipeWire portal (PipeWire Screen Capture source).
- Mic via PipeWire/Pulse audio input source.

Result: OBS captures screen + mic (+ optional webcam), scenes, start/stop, pause.

## Part 3 — Editing (kdenlive)

- `pkgs.kdenlive` added to `home.packages` in the same `recording.nix` module — full non-linear editor for cutting the OBS recording afterward.

## Out of scope

- No CI/nix-check changes beyond building the two hosts' configs.
- wf-recorder left as-is.
- No automated VM provisioning beyond `quickget` (Ubuntu installed interactively once).

## Verification

- `nix flake check` / build tehol config succeeds.
- After rebuild: `demo-vm create` downloads Ubuntu; `demo-vm start` boots a desktop; a file dropped in the shared folder appears in-guest; OBS lists a PipeWire screen source + mic; kdenlive opens.
