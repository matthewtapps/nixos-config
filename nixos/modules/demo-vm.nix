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
        DISK="''${CONF%.conf}/disk.qcow2"
        # List-driven delete: loop only while the tag still appears, so this
        # terminates regardless of qemu-img's exit code (deleting a missing tag
        # errors -> break). Operate on the disk directly with qemu-img.
        while ${pkgs.qemu-utils}/bin/qemu-img snapshot -l "$DISK" | awk '{print $2}' | grep -qx "$TAG"; do
          ${pkgs.qemu-utils}/bin/qemu-img snapshot -d "$TAG" "$DISK" || break
        done
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

  # Expose the demo VM's prod wtk-web to the LAN (e.g. samar's remote agent).
  # quickemu forwards these host ports into the guest via qemu hostfwd, bound on
  # all interfaces, so peers reach the VM at <tehol-lan-ip>:<port>. Requires
  # matching port_forwards=("9192:9192" "8443:443") in ~/VMs/ubuntu-24.04.conf.
  #   9192 -> guest 9192 : wtk grpc (agent provisioning channel; already open)
  #   8443 -> guest 443  : wtk web UI over HTTPS (443 is privileged on the host,
  #                        so qemu-as-user forwards from 8443 instead).
  networking.firewall.allowedTCPPorts = [ 8443 ];

  # quickemu needs /dev/kvm, which is owned by the kvm group.
  users.users = lib.genAttrs (builtins.attrNames host.users) (_: {
    extraGroups = lib.mkAfter [ "kvm" ];
  });
}
