{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../../programs/gitlab/default.nix
    ../../programs/zen/work.nix
  ];

  programs.mrRebase = {
    enable = true;
    host = "gitlab.countersight.co";
  };

  programs.ssh.settings."gitlab" = {
    HostName = "gitlab.countersight.co";
    Port = 2200;
  };

  # Port 22 is GitLab's git sshd, as on gitlab.
  programs.ssh.settings.portal = {
    header = "Host portal portal.countersight.co";
    Port = 2200;
  };

  # Bare work names like `nuc` only resolve with the suffix: wg0 carries
  # countersight.co as a routing domain, not a search domain (see wireguard.nix).
  programs.ssh.settings.countersight = {
    header = "Match all";
    CanonicalizeHostname = "yes";
    CanonicalDomains = "countersight.co";
    CanonicalizeFallbackLocal = "yes";
  };

  # Anything routed over the work VPN takes the nixos-hosts catalogue identity.
  # `ip route get` takes only an address, so resolve %h first. `git@` GitLab
  # is on wg0 too and needs the default keys.
  programs.ssh.settings.wireguard = {
    header = "Match !user git exec \"ip route get $(getent ahostsv4 %h | awk 'NR==1{print $1}') 2>/dev/null | grep -q ' dev wg0 '\"";
    User = "matthewt";
    IdentityFile = "~/.ssh/wtk-box";
    IdentitiesOnly = true;
  };

  home.packages = with pkgs; [
    thunderbird
    aerc
    teams-for-linux
    github-copilot-cli
    dbgate
    (pkgs.symlinkJoin {
      name = "element-desktop";
      paths = [
        # Electron does not know Hyprland, so it skips gnome-keyring unless told.
        (inputs.nixpkgs-element.legacyPackages.${pkgs.stdenv.hostPlatform.system}.element-desktop.override {
          commandLineArgs = "--password-store=gnome-libsecret";
        })
      ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      # Zen passes its LD_LIBRARY_PATH to the SSO callback launch; those libs
      # need a newer glibc than the pinned Electron has, so it crashes.
      postBuild = "wrapProgram $out/bin/element-desktop --unset LD_LIBRARY_PATH";
    })
    inputs.todone.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.claude-cowork.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
    disableGpu = false;
    wayland = {
      xwaylandOptimizations = true;
    };
    notificationMethod = "electron";
  };
}
