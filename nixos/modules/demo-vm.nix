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
        # SDL display: spicy/VirGL renders black on this Intel Arc iGPU, so use
        # SDL. $SHARE is still exposed to the guest (mount in-guest via 9p:
        # sudo mount -t 9p -o trans=virtio,version=9p2000.L Public-matt ~/shared).
        ${pkgs.quickemu}/bin/quickemu --vm "$CONF" --display sdl --public-dir "$SHARE"
        ;;
      snapshot)
        # Save current disk state under TAG (default 'clean'). One tag == one
        # snapshot: drop any existing snapshot(s) with this tag first so repeated
        # runs never stack duplicates. VM must be off (qcow2 write lock).
        TAG="''${2:-clean}"
        while ${pkgs.quickemu}/bin/quickemu --vm "$CONF" --snapshot delete "$TAG" >/dev/null 2>&1; do :; done
        ${pkgs.quickemu}/bin/quickemu --vm "$CONF" --snapshot create "$TAG"
        echo "Snapshot '$TAG' saved."
        ;;
      reset)
        # Throwaway: roll the disk back to snapshot TAG (default 'clean').
        TAG="''${2:-clean}"
        ${pkgs.quickemu}/bin/quickemu --vm "$CONF" --snapshot apply "$TAG"
        ;;
      *)
        echo "usage: demo-vm {create|start|snapshot [tag]|reset [tag]}"
        echo "  create        - download Ubuntu 24.04 into ~/VMs"
        echo "  start         - boot with SDL + ~/VMs/shared exposed to guest"
        echo "  snapshot [tag]- save disk state as [tag] (default 'clean'); replaces same tag"
        echo "  reset [tag]   - restore snapshot [tag] (default 'clean'); throwaway"
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
