{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  zen = import ./lib.nix { inherit pkgs config inputs; };
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  # Zen creates the group database on first run, so this applies from the
  # second switch on, like the pins.
  home.activation.zen-profile-group = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    let
      db = "${config.programs.zen-browser.configPath}/Profile Groups/${zen.storeId}.sqlite";
      row =
        name: p:
        let
          q = s: "'${lib.replaceStrings [ "'" ] [ "''" ] s}'";
        in
        "(${q p.path}, ${q name}, ${q (zen.avatars.${name} or "star")}, 'default-theme@mozilla.org', '#000000', ${
          q p.settings."zen.theme.accent-color"
        })";
      rows = lib.concatStringsSep ", " (lib.mapAttrsToList row config.programs.zen-browser.profiles);
    in
    ''
      if [ -f ${lib.escapeShellArg db} ]; then
        ${lib.getExe pkgs.sqlite} -cmd '.timeout 5000' ${lib.escapeShellArg db} \
          ${lib.escapeShellArg "INSERT INTO Profiles (path, name, avatar, themeId, themeFg, themeBg) VALUES ${rows} ON CONFLICT(path) DO UPDATE SET name = excluded.name, avatar = excluded.avatar, themeFg = excluded.themeFg, themeBg = excluded.themeBg;"}
      else
        echo "zen-profile-group: no group database yet; open Zen once and switch again"
      fi
    ''
  );

  # zen-reconcile diffs live shortcuts against this. Zen's file marks no
  # user edits, so the baseline is the state right after declared ones apply.
  home.activation.zen-shortcuts-baseline = lib.hm.dag.entryAfter (map (n: "zen-browser-${n}") (
    builtins.attrNames config.programs.zen-browser.profiles
  )) (
    lib.concatMapStrings (p: ''
      dir=${lib.escapeShellArg "${config.programs.zen-browser.configPath}/${p.path}"}
      if [ -f "$dir/zen-keyboard-shortcuts.json" ] && [ -f "$dir/prefs.js" ]; then
        ver=$(${pkgs.gnused}/bin/sed -n 's/^user_pref("zen.keyboard.shortcuts.version", \([0-9]*\));$/\1/p' "$dir/prefs.js")
        have=$(${lib.getExe pkgs.jq} -r '.version' "$dir/zen-shortcuts-baseline.json" 2>/dev/null || true)
        if [ -n "$ver" ] && [ "$ver" != "$have" ]; then
          if ${lib.getExe pkgs.jq} --argjson v "$ver" '{version: $v, shortcuts: .shortcuts}' \
            "$dir/zen-keyboard-shortcuts.json" > "$dir/zen-shortcuts-baseline.json.tmp"; then
            mv "$dir/zen-shortcuts-baseline.json.tmp" "$dir/zen-shortcuts-baseline.json"
          else
            rm -f "$dir/zen-shortcuts-baseline.json.tmp"
            echo "zen-shortcuts-baseline: could not read $dir/zen-keyboard-shortcuts.json, skipped"
          fi
        fi
      fi
    '') (builtins.attrValues config.programs.zen-browser.profiles)
  );

  home.packages = [
    (
      let
        py = pkgs.python3.withPackages (p: [
          p.lz4
          p.textual
        ]);
      in
      pkgs.runCommand "zen-tools" { } ''
        mkdir -p $out/bin $out/lib/zen-tools
        cp ${./zen_profile.py} $out/lib/zen-tools/zen_profile.py
        cp ${./zen-export.py} $out/lib/zen-tools/zen-export.py
        cp ${./zen-reconcile.py} $out/lib/zen-tools/zen-reconcile.py
        for t in zen-export zen-reconcile; do
          printf '#!/bin/sh\nexec %s %s "$@"\n' ${py}/bin/python3 $out/lib/zen-tools/$t.py > $out/bin/$t
          chmod +x $out/bin/$t
        done
      ''
    )
  ];

  programs.zen-browser = {
    enable = true;
    unwrappedPackage = import ./zen-patched.nix { inherit pkgs inputs; };
    # Bitwarden and 1Password own logins, cards and addresses.
    policies = {
      PasswordManagerEnabled = false;
      OfferToSaveLogins = false;
      AutofillCreditCardEnabled = false;
      AutofillAddressEnabled = false;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
      ExtensionSettings = lib.genAttrs (map (e: e.addonId) (
        zen.extensions.shared ++ zen.extensions.personal ++ zen.extensions.work
      )) (_: { private_browsing = true; });
    };
    profiles = {
      Personal =
        zen.mkProfile {
          id = 0;
          path = "personal";
          extensions = zen.extensions.shared ++ zen.extensions.personal;
        }
        // {
          isDefault = lib.mkDefault true;
          storeId = lib.mkDefault zen.storeId;
        };
      Professional = lib.mkMerge [
        (zen.mkProfile {
          id = 1;
          path = "professional";
          extensions = zen.extensions.shared ++ zen.extensions.personal;
        })
        (zen.themed "tokyo-night-dark")
      ];
    };
  };
}
