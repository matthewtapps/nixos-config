# nixos/modules/azure-vpn.nix
{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.programs.azure-vpn;

  azureVpnPackage = pkgs.callPackage ../packages/azure-vpn.nix { };
in

{
  options.programs.azure-vpn = {
    enable = lib.mkEnableOption "Microsoft Azure VPN Client";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users who can use the Azure VPN client";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ azureVpnPackage ];

    # Required certificates
    environment.etc = {
      "ssl/certs/DigiCert_Global_Root_G2.pem".text = ''
        -----BEGIN CERTIFICATE-----
        MIIDjjCCAnagAwIBAgIQAzrx5qcRqaC7KGSxHQn65TANBgkqhkiG9w0BAQsFADBh
        MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
        d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBH
        MjAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAwMDBaMGExCzAJBgNVBAYTAlVT
        MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
        b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IEcyMIIBIjANBgkqhkiG
        9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuzfNNNx7a8myaJCtSnX/RrohCgiN9RlUyfuI
        2/Ou8jqJkTx65qsGGmvPrC3oXgkkRLpimn7Wo6h+4FR1IAWsULecYxpsMNzaHxmx
        1x7e/dfgy5SDN67sH0NO3Xss0r0upS/kqbitOtSZpLYl6ZtrAGCSYP9PIUkY92eQ
        q2EGnI/yuum06ZIya7XzV+hdG82MHauVBJVJ8zUtluNJbd134/tJS7SsVQepj5Wz
        tCO7TG1F8PapspUwtP1MVYwnSlcUfIKdzXOS0xZKBgyMUNGPHgm+F6HmIcr9g+UQ
        vIOlCsRnKPZzFBQ9RnbDhxSJITRNrw9FDKZJobq7nMWxM4MphQIDAQABo0IwQDAP
        BgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjAdBgNVHQ4EFgQUTiJUIBiV
        5uNu5g/6+rkS7QYXjzkwDQYJKoZIhvcNAQELBQADggEBAGBnKJRvDkhj6zHd6mcY
        1Yl9PMWLSn/pvtsrF9+wX3N3KjITOYFnQoQj8kVnNeyIv/iPsGEMNKSuIEyExtv4
        NeF22d+mQrvHRAiGfzZ0JFrabA0UWTW98kndth/Jsw1HKj2ZL7tcu7XUIOGZX1NG
        Fdtom/DzMNU+MeKNhJ7jitralj41E6Vf8PlwUHBHQRFXGU7Aj64GxJUTFy8bJZ91
        8rGOmaFvE7FBcf6IKshPECBV1/MUReXgRPTqh5Uykw7+U0b6LJ3/iyK5S9kJRaTe
        pLiaWN0bfVKfjllDiIGknibVb63dDcY3fe0Dkhvld1927jyNxF1WW6LZZm6zNTfl
        MrY=
        -----END CERTIFICATE-----
      '';
    };

    # Security wrapper with necessary capabilities
    security.wrappers = {
      microsoft-azurevpnclient = {
        owner = "root";
        group = "root";
        capabilities = "cap_net_admin,cap_net_raw,cap_net_bind_service,cap_setpcap,cap_setuid,cap_setgid,cap_sys_admin,cap_dac_override,cap_chown,cap_fowner+ep";
        source = "${azureVpnPackage}/bin/microsoft-azurevpnclient";
      };
    };

    security.sudo.extraRules = [
      {
        users = [ "matt" ];
        commands = [
          {
            command = "/run/wrappers/bin/microsoft-azurevpnclient";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Systemd-resolved configuration
    services.resolved = {
      enable = true;
      dnssec = "false";
      domains = [ "~." ];
      fallbackDns = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      extraConfig = ''
        DNSStubListener=yes
        ResolveUnicastSingleLabel=yes
        Cache=yes
      '';
    };

    # D-Bus permissions for Azure VPN
    services.dbus.packages = [
      pkgs.gnome-keyring
      (pkgs.writeTextFile {
        name = "azurevpn-dbus-policy";
        destination = "/share/dbus-1/system.d/org.freedesktop.resolve1.AzureVPN.conf";
        text = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
          "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
          <busconfig>
            <policy user="root">
              <allow own="org.freedesktop.resolve1"/>
              <allow send_destination="org.freedesktop.resolve1"/>
            </policy>
            
            <policy context="default">
              <allow send_destination="org.freedesktop.resolve1"
                     send_interface="org.freedesktop.resolve1.Manager"
                     send_member="SetLinkDNS"/>
              <allow send_destination="org.freedesktop.resolve1"
                     send_interface="org.freedesktop.resolve1.Manager" 
                     send_member="SetLinkDomains"/>
              <allow send_destination="org.freedesktop.resolve1"
                     send_interface="org.freedesktop.resolve1.Manager"
                     send_member="SetLinkDefaultRoute"/>
              <allow send_destination="org.freedesktop.resolve1"
                     send_interface="org.freedesktop.resolve1.Manager"
                     send_member="RevertLink"/>
              <allow send_destination="org.freedesktop.resolve1"
                     send_interface="org.freedesktop.DBus.Properties"
                     send_member="Get"/>
              <allow send_destination="org.freedesktop.resolve1"
                     send_interface="org.freedesktop.DBus.Properties"
                     send_member="GetAll"/>
              <allow send_destination="org.freedesktop.resolve1"
                     send_interface="org.freedesktop.DBus.Introspectable"
                     send_member="Introspect"/>
              <allow send_destination="org.freedesktop.resolve1"
                     send_interface="org.freedesktop.DBus.Peer"
                     send_member="Ping"/>
            </policy>

            ${lib.concatMapStringsSep "\n" (user: ''
              <policy user="${user}">
                <allow send_destination="org.freedesktop.resolve1"/>
              </policy>
            '') cfg.users}
          </busconfig>
        '';
      })
    ];

    # Polkit rules for network management
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id.indexOf("org.freedesktop.resolve1.") == 0 ||
            action.id.indexOf("org.freedesktop.NetworkManager.") == 0) {
          if (subject.programPath &&
              (subject.programPath.indexOf("microsoft-azurevpnclient") >= 0 ||
               subject.programPath.indexOf("openvpn") >= 0)) {
            return polkit.Result.YES;
          }
          
          ${lib.concatMapStringsSep "\n        " (user: ''
            if (subject.user == "${user}") {
              return polkit.Result.YES;
            }
          '') cfg.users}
        }
        
        if (action.id == "org.freedesktop.resolve1.set-dns-servers" ||
            action.id == "org.freedesktop.resolve1.set-domains" ||
            action.id == "org.freedesktop.resolve1.set-default-route" ||
            action.id == "org.freedesktop.resolve1.set-link-dns" ||
            action.id == "org.freedesktop.resolve1.set-link-domains" ||
            action.id == "org.freedesktop.resolve1.set-link-default-route" ||
            action.id == "org.freedesktop.resolve1.revert-link") {
          ${lib.concatMapStringsSep "\n          " (user: ''
            if (subject.user == "${user}") {
              return polkit.Result.YES;
            }
          '') cfg.users}
        }
      });
    '';

    # Add users to networkmanager group
    users.users = lib.genAttrs cfg.users (user: {
      extraGroups = [ "networkmanager" ];
    });
  };
}
