{ pkgs, ... }:
{
  programs.zathura = {
    enable = true;
    package = pkgs.zathura.override {
      plugins = [ pkgs.zathuraPkgs.zathura_pdf_mupdf ];
    };
    options = {
      # Page display
      pages-per-row = 1;
      scroll-page-aware = true;
      scroll-full-overlap = 0.01;
      scroll-step = 150;
      adjust-open = "best-fit";
      double-click-follow = false;
      advance-pages-per-row = true;

      # Optional: nicer defaults
      selection-clipboard = "clipboard";
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 1;
    };
  };
}
