{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  elementPkgs = inputs.nixpkgs-element.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  base16 = inputs.stylix.inputs.base16.lib { inherit pkgs lib; };
  # Hard, as in kitty: the Stylix soft background washes out Element's text.
  c = lib.mapAttrs (_: v: "#${v}") (
    base16.mkSchemeAttrs "${pkgs.base16-schemes}/share/themes/everforest-dark-hard.yaml"
  );
  mix = a: pct: b: "color-mix(in srgb, ${a} ${toString pct}%, ${b})";
  steps = lib.genList (i: (i + 1) * 100) 14;
  # Ramps follow the stock Compound dark palette, where step 900 is the accent.
  # Step 900 is secondary text and 1400 is primary text.
  grays = [
    (mix c.base01 50 c.base00)
    c.base01
    (mix c.base02 50 c.base01)
    c.base02
    (mix c.base03 25 c.base02)
    (mix c.base03 50 c.base02)
    (mix c.base03 75 c.base02)
    c.base03
    c.base04
    (mix c.base05 33 c.base04)
    (mix c.base05 66 c.base04)
    c.base05
    (mix c.base06 50 c.base05)
    c.base06
  ];
  huePct = [ 10 12 15 20 28 35 45 65 100 15 30 50 70 85 ];
  ramp = name: f: lib.listToAttrs (lib.imap0 (i: n: lib.nameValuePair "--cpd-color-${name}-${toString n}" (f i)) steps);
  hue = accent: i:
    let p = builtins.elemAt huePct i; in
    if i < 8 then mix accent p c.base00 else if i == 8 then accent else mix c.base05 p accent;
  hues = {
    green = c.base0B; lime = c.base0B; red = c.base08; orange = c.base09;
    yellow = c.base0A; cyan = c.base0C; blue = c.base0D;
    purple = c.base0E; fuchsia = c.base0E; pink = c.base0F;
  };
  stylixTheme = {
    name = "Stylix";
    is_dark = true;
    # Legacy keys still drive parts of a custom theme, like row hover. Element
    # derives alpha variants from them, so they must be hex.
    colors = {
      accent-color = c.base0B;
      primary-color = c.base0B;
      warning-color = c.base08;
      sidebar-color = c.base00;
      roomlist-background-color = c.base00;
      roomlist-text-color = c.base05;
      roomlist-text-secondary-color = c.base04;
      roomlist-highlights-color = c.base02;
      roomlist-separator-color = c.base02;
      timeline-background-color = c.base00;
      timeline-text-color = c.base05;
      timeline-text-secondary-color = c.base04;
      timeline-highlights-color = c.base01;
      reaction-row-button-selected-bg-color = c.base02;
    };
    compound = {
      "--cpd-color-theme-bg" = c.base00;
    }
    // ramp "gray" (builtins.elemAt grays)
    // lib.concatMapAttrs (name: accent: ramp name (hue accent)) hues;
  };
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
      # An account-level theme choice in Settings > Appearance overrides these.
      default_theme = "custom-Stylix";
      setting_defaults = {
        custom_themes = [ stylixTheme ];
        use_system_theme = false;
      };
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
      # The pinned Electron is EOL, and its glibc is too old for the system
      # Mesa and for the LD_LIBRARY_PATH Zen passes to the SSO callback launch.
      electron_42 = pkgs.electron_44;
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
