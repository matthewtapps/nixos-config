{ pkgs, inputs }:
# Upstream fb80623e2 returns early on re-entry before clearing the edge-exit
# hide timer, so the compact sidebar closes while hovered. Drop when fixed.
inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta-unwrapped.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
    pkgs.unzip
    pkgs.zip
  ];
  postInstall = (old.postInstall or "") + ''
    omni=$(echo $out/lib/zen-bin-*/browser/omni.ja)
    work=$(mktemp -d)
    # Mozilla's optimised jar layout makes unzip report errors but extract fine.
    unzip -q "$omni" -d "$work" || [ $? -le 2 ]
    substituteInPlace "$work/chrome/browser/content/browser/zen-components/ZenCompactMode.mjs" \
      --replace-fail \
        '        if (target.hasAttribute("zen-has-hover")) {
              return;' \
        '        if (target.hasAttribute("zen-has-hover")) {
              this.clearFlashTimeout("has-hover" + target.id);
              return;'
    chmod -R u+w "$(dirname "$omni")"
    rm "$omni"
    (cd "$work" && zip -qr0XD "$omni" .)
  '';
})
