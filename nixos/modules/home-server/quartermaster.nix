{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  quartermaster = inputs.lsag-quartermaster.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  users.users.quartermaster = {
    isSystemUser = true;
    group = "quartermaster";
  };
  users.groups.quartermaster = { };

  systemd.services.quartermaster = {
    description = "Quartermaster cart store";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart = "${lib.getExe quartermaster.cart-server} --database /var/lib/quartermaster/carts.sqlite --listen 127.0.0.1:8081";
      User = "quartermaster";
      Group = "quartermaster";
      StateDirectory = "quartermaster";
      StateDirectoryMode = "0700";
      Restart = "on-failure";
      RestartSec = 5;

      CapabilityBoundingSet = [ "" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
        "~@resources"
      ];
    };
  };
}
