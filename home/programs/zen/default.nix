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

  home.packages = [
    (pkgs.writers.writePython3Bin "zen-export" {
      libraries = [ pkgs.python3Packages.lz4 ];
      flakeIgnore = [ "E501" ];
    } (builtins.readFile ./zen-export.py))
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
          file = ./profiles/personal.json;
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
          file = ./profiles/professional.json;
          extensions = zen.extensions.shared ++ zen.extensions.personal;
        })
        (zen.themed "tokyo-night-dark")
      ];
    };
  };
}
