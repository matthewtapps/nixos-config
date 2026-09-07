{ pkgs, ... }:
{
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-archive-plugin
    thunar-volman
  ];

  # Enables preferences to be saved
  programs.xfconf.enable = true;

  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Lets Thunar list unmounted volumes in its sidebar and mount them on click.
  services.udisks2.enable = true;

  # Windows fast startup leaves NTFS dirty, and a dirty volume mounts read-only.
  boot.supportedFilesystems.ntfs = true;

  # udisks2 sets HintSystem on every SATA and NVMe drive, so mounting one asks
  # for an admin password. Waive that for wheel to keep the Windows data drives
  # a single click away in Thunar.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
           action.id == "org.freedesktop.udisks2.filesystem-unmount-others") &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';
}
