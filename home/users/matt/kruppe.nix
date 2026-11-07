_: {
  imports = [
    ./common.nix
    ./common-personal.nix
  ];

  # Broadwell decodes H.264 but not VP9 or AV1, so YouTube must serve H.264.
  programs.zen-browser.profiles.Personal.settings = {
    "media.av1.enabled" = false;
    "media.mediasource.vp9.enabled" = false;
    "media.hardware-video-decoding.force-enabled" = true;
  };
}
