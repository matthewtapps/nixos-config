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
