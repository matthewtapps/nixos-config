{ pkgs, ... }:

{
  fonts.fontDir.enable = true;

  # dejavu, freefont, gyre (substitutes for the standard PostScript 35),
  # liberation, unifont, noto CJK sans/serif and colour emoji. Broad Unicode
  # coverage so a document asking for a font we don't have degrades to
  # something readable instead of tofu.
  fonts.enableDefaultPackages = true;

  fonts.packages = with pkgs; [
    noto-fonts
    font-awesome
    geist-font
    nerd-fonts.geist-mono

    # Microsoft fonts. Without these, .docx/.pptx text is substituted at a
    # different metric, reflows onto a different number of lines and overflows
    # its boxes - which is most of what looks like the office suite mangling
    # the document.
    corefonts # Arial, Times New Roman, Courier New, Georgia, Verdana, Trebuchet, Impact, Webdings
    vista-fonts # Calibri, Cambria, Candara, Consolas, Constantia, Corbel (Office 2007+ defaults)

    # Metric-compatible clones of Calibri/Cambria, for documents that name
    # these directly rather than the Microsoft originals.
    caladea # Cambria metrics
    carlito # Calibri metrics
  ];
}
