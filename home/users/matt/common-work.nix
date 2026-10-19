{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  elementPkgs = inputs.nixpkgs-element.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # Matches the Element Web config chat.countersight.co serves.
  elementWeb = elementPkgs.element-web.override {
    conf = {
      default_server_config."m.homeserver" = {
        base_url = "https://chat.countersight.co";
        server_name = "chat.countersight.co";
      };
      disable_custom_urls = true;
      disable_guests = true;
      element_call.use_exclusively = true;
      features.feature_group_calls = true;
      # Resolved from webapp/bundles/<hash>/init.js; Desktop serves only webapp/.
      # co.countersight.klipy_api_key is set by hand in
      # ~/.config/Element/config.json, which Desktop lays over this config.
      modules = [ "../../modules/gif-picker.js" ];
    };
  };
  # Copied, not linked: Desktop's asar packing rejects links out of the tree.
  element-web = pkgs.runCommand "element-web-countersight" { } ''
    cp -rL ${elementWeb} $out
    chmod u+w $out
    mkdir $out/modules
    cp ${./element-gif-picker.js} $out/modules/gif-picker.js
  '';
in
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
    (elementPkgs.element-desktop.override {
      inherit element-web;
      # The pinned Electron's glibc is too old for the system Mesa and for the
      # LD_LIBRARY_PATH Zen passes to the SSO callback launch.
      electron_42 = pkgs.electron_42;
      # Electron does not know Hyprland, so it skips gnome-keyring unless told.
      commandLineArgs = "--password-store=gnome-libsecret";
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
