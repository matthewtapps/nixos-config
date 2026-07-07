# Demo VM + Screen Recording Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a one-command persistent-but-resettable Ubuntu demo VM (quickemu) and an OBS + kdenlive screen/mic recording-and-editing toolchain to the tehol host.

**Architecture:** One new NixOS system module (`demo-vm.nix`) ships quickemu + a `demo-vm` wrapper script and grants `/dev/kvm` access; one new home-manager module (`recording.nix`) enables OBS Studio (PipeWire capture) and installs kdenlive. Each is wired into tehol's existing per-host import lists.

**Tech Stack:** NixOS flake, home-manager (integrated as a NixOS module), quickemu 4.9.9, OBS Studio + obs-pipewire-audio-capture plugin, kdenlive (`kdePackages.kdenlive`).

**Verification model:** This is declarative Nix config, not a codebase with a unit-test runner. "Test" = the config evaluates and builds. Build without applying:
`nix build .#nixosConfigurations.tehol.config.system.build.toplevel`
Apply (existing alias, needs sudo): `nixswitch` → `sudo nixos-rebuild switch --flake $HOME/nixos-config#tehol`. Interactive GUI/VM behavior is verified manually in the final task.

---

## File Structure

- Create: `nixos/modules/demo-vm.nix` — quickemu package, `demo-vm` wrapper, kvm group membership.
- Modify: `nixos/hosts/tehol.nix` — add `../modules/demo-vm.nix` to `imports`.
- Create: `home/programs/recording.nix` — OBS Studio (+ plugin) and kdenlive.
- Modify: `home/users/matt/tehol.nix` — add `../../programs/recording.nix` to `imports`.

---

## Task 1: Demo VM system module (quickemu + wrapper + kvm access)

**Files:**
- Create: `nixos/modules/demo-vm.nix`
- Modify: `nixos/hosts/tehol.nix` (imports list, currently lines 4-18)

- [ ] **Step 1: Create the module**

Create `nixos/modules/demo-vm.nix` with exactly this content. The `host` / `lib.genAttrs` group pattern mirrors `nixos/modules/virtualization.nix`. Flags are from quickemu 4.9.9: `--display spice`, `--public-dir <path>`, `--snapshot create|apply <tag>`.

```nix
{ pkgs, host, lib, ... }:
let
  # Fixed layout so VMs, snapshots, and the host<->guest share dir live in one
  # predictable place instead of the current working directory.
  demo-vm = pkgs.writeShellScriptBin "demo-vm" ''
    set -euo pipefail
    VMDIR="$HOME/VMs"
    SHARE="$VMDIR/shared"
    CONF="ubuntu-24.04.conf"
    mkdir -p "$SHARE"
    cd "$VMDIR"

    case "''${1:-}" in
      create)
        # Downloads the Ubuntu 24.04 ISO and writes ubuntu-24.04.conf into $VMDIR.
        ${pkgs.quickemu}/bin/quickget ubuntu 24.04
        echo "Created. Run 'demo-vm start' to boot and install Ubuntu."
        ;;
      start)
        # SPICE display: full GNOME desktop in a spicy window, clipboard sync,
        # drag-and-drop, and $SHARE exposed to the guest over spice-webdav.
        ${pkgs.quickemu}/bin/quickemu --vm "$CONF" --display spice --public-dir "$SHARE"
        ;;
      snapshot)
        # Run once after a clean install to mark the pristine state.
        ${pkgs.quickemu}/bin/quickemu --vm "$CONF" --snapshot create clean
        ;;
      reset)
        # Throwaway: roll the disk back to the 'clean' snapshot.
        ${pkgs.quickemu}/bin/quickemu --vm "$CONF" --snapshot apply clean
        ;;
      *)
        echo "usage: demo-vm {create|start|snapshot|reset}"
        echo "  create   - download Ubuntu 24.04 into ~/VMs"
        echo "  start    - boot with SPICE + ~/VMs/shared exposed to guest"
        echo "  snapshot - save current disk state as 'clean' (run after install)"
        echo "  reset    - restore the 'clean' snapshot (throwaway)"
        exit 1
        ;;
    esac
  '';
in
{
  environment.systemPackages = [ pkgs.quickemu demo-vm ];

  # quickemu needs /dev/kvm, which is owned by the kvm group.
  users.users = lib.genAttrs (builtins.attrNames host.users) (_: {
    extraGroups = lib.mkAfter [ "kvm" ];
  });
}
```

- [ ] **Step 2: Wire it into the tehol host**

In `nixos/hosts/tehol.nix`, add the import next to the existing `../modules/virtualization.nix` line:

```nix
    ../modules/virtualization.nix
    ../modules/demo-vm.nix
```

- [ ] **Step 3: Build to verify it evaluates**

Run: `nix build .#nixosConfigurations.tehol.config.system.build.toplevel`
Expected: builds successfully, no eval errors. (Confirms the module, the `host`/`lib.genAttrs` usage, and the wrapper's Nix string all parse.)

- [ ] **Step 4: Commit**

```bash
git add nixos/modules/demo-vm.nix nixos/hosts/tehol.nix
git commit -m "feat(tehol): quickemu demo VM module with demo-vm wrapper"
```

---

## Task 2: Recording home module (OBS + kdenlive)

**Files:**
- Create: `home/programs/recording.nix`
- Modify: `home/users/matt/tehol.nix` (imports list)

- [ ] **Step 1: Create the module**

Create `home/programs/recording.nix`. `programs.obs-studio` is the home-manager module; screen capture rides the Hyprland PipeWire portal already configured in `nixos/modules/wayland.nix`, so no portal setup is needed here.

```nix
{ pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      # Per-application / clean microphone audio capture on PipeWire.
      obs-pipewire-audio-capture
    ];
  };

  # Non-linear editor for cutting the OBS recording afterward.
  home.packages = [ pkgs.kdePackages.kdenlive ];
}
```

- [ ] **Step 2: Wire it into matt@tehol**

In `home/users/matt/tehol.nix`, add the import:

```nix
{ pkgs, ... }:
{
  imports = [
    ./common.nix
    ./common-work.nix
    ../../programs/recording.nix
  ];
}
```

- [ ] **Step 3: Build to verify it evaluates**

Run: `nix build .#nixosConfigurations.tehol.config.system.build.toplevel`
Expected: builds successfully. (The integrated home-manager module means the system build also evaluates matt's home config, including `programs.obs-studio` and the kdenlive package.)

- [ ] **Step 4: Commit**

```bash
git add home/programs/recording.nix home/users/matt/tehol.nix
git commit -m "feat(tehol): OBS Studio + kdenlive recording toolchain"
```

---

## Task 3: Apply and verify end-to-end

**Files:** none (activation + manual verification).

- [ ] **Step 1: Apply the configuration**

Run: `nixswitch`
Expected: switches to the new generation without error. (Alias resolves to `sudo nixos-rebuild switch --flake $HOME/nixos-config#tehol`.)

- [ ] **Step 2: Confirm kvm group membership**

Run: `id -nG | tr ' ' '\n' | grep -x kvm`
Expected: prints `kvm`.
Note: group membership needs a fresh login session to take effect. If it does not appear, log out and back in (or reboot), then re-check.

- [ ] **Step 3: Verify the VM tooling**

Run: `demo-vm` (no args)
Expected: prints the usage/help text.
Then run: `demo-vm create`
Expected: quickget downloads Ubuntu 24.04 into `~/VMs/` and writes `ubuntu-24.04.conf`.
Then run: `demo-vm start`
Expected: a spicy window opens showing the Ubuntu installer/desktop. Install Ubuntu (interactive, one time).

- [ ] **Step 4: Verify file transfer + snapshot lifecycle**

- Drop a file into `~/VMs/shared` on the host; confirm it appears in the guest's mounted share (or via drag-and-drop / clipboard paste into the VM window).
- With Ubuntu installed to a clean state, run: `demo-vm snapshot` → expected: creates snapshot `clean`.
- Change something in the guest, shut down, then run: `demo-vm reset` → expected: `--snapshot apply clean` succeeds; next `demo-vm start` boots the pristine state.

- [ ] **Step 5: Verify recording + editing**

- Launch OBS Studio. Add a source → expected: "Screen Capture (PipeWire)" is available and, when added, the Hyprland portal picker appears and captures the screen.
- In OBS audio settings/sources → expected: the microphone is selectable as an input.
- Do a short test recording, then open it in kdenlive (`kdenlive`) → expected: kdenlive launches and imports the clip.

- [ ] **Step 6: Commit any doc/tweak follow-ups (if needed)**

If interactive verification surfaced a needed tweak (e.g. a wrapper flag adjustment), make it, rebuild, and commit:

```bash
git add -A
git commit -m "fix(tehol): adjust demo-vm/recording after verification"
```

---

## Self-Review Notes

- **Spec coverage:** Part 1 VM → Task 1 + Task 3 steps 3-4; file transfer → Task 1 `--public-dir` + Task 3 step 4; persistent+throwaway → snapshot/reset subcommands. Part 2 OBS → Task 2 + Task 3 step 5. Part 3 kdenlive → Task 2 + Task 3 step 5. All covered.
- **Corrections vs spec:** spec said `--snapshot restore`; quickemu 4.9.9's actual verb is `--snapshot apply` — plan uses `apply`. Shared folder uses quickemu's real `--public-dir` flag (default is xdg PUBLICSHARE) pointed at `~/VMs/shared`.
- **Verified package/module names:** `pkgs.quickemu` (4.9.9), `pkgs.obs-studio-plugins.obs-pipewire-audio-capture` (1.2.1), `pkgs.kdePackages.kdenlive` (26.04.2), `programs.obs-studio` HM module. `kvm-intel` already loaded on tehol; Hyprland PipeWire portal already present.
