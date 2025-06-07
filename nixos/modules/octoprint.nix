{ pkgs, ... }:
{
  services.octoprint = {
    enable = true;
    user = "matt";
  };

  environment.systemPackages = with pkgs; [
    (orca-slicer.overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [
        intel-media-driver # Intel media/compute libraries
        onetbb # Intel Threading Building Blocks (includes OpenMP)
      ];
      # Add Intel OpenMP to the runtime path
      postInstall =
        (old.postInstall or "")
        + ''
          wrapProgram $out/bin/orca-slicer \
            --prefix LD_LIBRARY_PATH : ${pkgs.onetbb}/lib
        '';
    }))
  ];
}
