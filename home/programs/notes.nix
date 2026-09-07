{ config, pkgs, ... }:

let
  notesDir = "${config.home.homeDirectory}/notes";
  notes-clone = pkgs.writeShellApplication {
    name = "notes-clone";
    runtimeInputs = [
      pkgs.git
      pkgs.git-crypt
      pkgs.openssh
    ];
    text = ''
      # accept-new: a fresh host has no known_hosts entry for github.com yet.
      export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"
      git clone git@github.com:matthewtapps/notes.git ${notesDir}
      cd ${notesDir}
      git-crypt unlock /run/secrets/notes-git-crypt-key
    '';
  };
in
{
  # git-crypt must be on the session PATH: obsidian-git and plain git shell
  # out to it for the encrypt and decrypt filters.
  home.packages = [ pkgs.git-crypt ];

  systemd.user.services.notes-clone = {
    Unit = {
      Description = "Clone and unlock the notes vault";
      After = [ "network-online.target" ];
      ConditionPathExists = "!${notesDir}/.git";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${notes-clone}/bin/notes-clone";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
