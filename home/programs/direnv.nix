_: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableNushellIntegration = true;

    # nix-direnv's gcroot touch matches the .rc cache file, so a parent .envrc
    # loaded via source_up re-evaluates its flake on every load. Only the
    # profile symlinks are gcroots.
    stdlib = ''
      _nix_refresh_gcroots() {
        local layout_dir root
        layout_dir=$(direnv_layout_dir)
        for root in "$layout_dir"/flake-profile-* "$layout_dir"/flake-inputs/* "$layout_dir"/nix-profile-*; do
          if [[ -L $root ]]; then
            touch -h "$root" || _nix_direnv_warning "could not refresh gcroots; layout directory may be read-only"
          fi
        done
      }
    '';
  };
}
