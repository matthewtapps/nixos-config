# mr-rebase brings a stack of open merge requests up to date without opening
# each one. Authentication comes from glab, so no token lands in the store:
# run `glab auth login --hostname <host>` once per host.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.mrRebase;

  mr-rebase = pkgs.writeShellApplication {
    name = "mr-rebase";
    runtimeInputs = with pkgs; [
      glab
      jq
      git
      coreutils
    ];
    text = ''
      export MR_REBASE_HOST="''${MR_REBASE_HOST:-${cfg.host}}"
      export MR_REBASE_PROJECT="''${MR_REBASE_PROJECT:-${cfg.project}}"

      ${builtins.readFile ./mr-rebase.sh}
    '';
  };
in
{
  options.programs.mrRebase = {
    enable = lib.mkEnableOption "the mr-rebase bulk merge request rebase script";

    host = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "gitlab.example.com";
      description = ''
        GitLab host used when --host is unset and the project did not come from
        the origin remote of the current directory.
      '';
    };

    project = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "group/project";
      description = ''
        Project used when --repo is unset. Empty falls back to the origin remote
        of the current directory.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.glab
      mr-rebase
    ];
  };
}
