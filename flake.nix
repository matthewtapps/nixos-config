{
  description = "Matthew Tapps NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";

    nix-colors.url = "github:misterio77/nix-colors";
    ags.url = "github:Aylur/ags";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    zen-browser.url = "github:MarceColl/zen-browser-flake";

    # darwin.inputs.nixpkgs.follows = "nixpkgs";
    # darwin.url = "github:lnl7/nix-darwin/master";

    # impermanence.url =
    #   "github:nix-community/impermanence/63f4d0443e32b0dd7189001ee1894066765d18a5";
  };

  outputs =
    {
      nixpkgs,
      nixos,
      home-manager,
      nixos-wsl,
      ...
    }@inputs:
    let
      overlays = [ inputs.neovim-nightly-overlay.overlays.default ];

      config = {
        allowUnfree = true;
      };

      nixosPackages = import nixos {
        system = "x86_64-linux";
        inherit config overlays;
      };

      x86Pkgs = import nixpkgs {
        system = "x86_64-linux";
        inherit config overlays;
      };

      # armPkgs = import nixpkgs {
      #   system = "aarch64-linux";
      #   config = {
      #     allowUnfree = true;
      #     allowUnsupportedSystem = true;
      #   };
      # };

      palette = inputs.nix-colors.colorSchemes.everforest-dark-hard.palette;

      theme = {
        colorScheme = {
          transparencyBackgroundHex = "CC";
          transparencyForegroundHex = "EE";
          transparencyHeavyShadeHex = "5C";
          transparencyLightShadeHex = "14";

          transparencyBackgroundRGB = "0.8";
          transparencyForegroundRGB = "0.93";
          transparencyHeavyShadeRGB = "0.36";
          transparencyLightShadeRGB = "0.08";

          background1Hex = palette.base00;
          background2Hex = palette.base01;
          background3Hex = palette.base02;
          background4Hex = palette.base03;
          foreground4Hex = palette.base04;
          foreground3Hex = palette.base05;
          foreground2Hex = palette.base06;
          foreground1Hex = palette.base07;

          background1RGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base00;
          background2RGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base01;
          background3RGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base02;
          background4RGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base03;
          foreground4RGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base04;
          foreground3RGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base05;
          foreground2RGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base06;
          foreground1RGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base07;

          redHex = palette.base08;
          orangeHex = palette.base09;
          yellowHex = palette.base0A;
          greenHex = palette.base0B;
          cyanHex = palette.base0C;
          blueHex = palette.base0D;
          magentaHex = palette.base0E;
          brownHex = palette.base0F;

          redRGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base08;
          orangeRGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base09;
          yellowRGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base0A;
          greenRGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base0B;
          cyanRGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base0C;
          blueRGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base0D;
          magentaRGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base0E;
          brownRGB = inputs.nix-colors.lib.conversions.hexToRGBString "," palette.base0F;

          accentHex = theme.colorScheme.cyanHex;
          secondaryAccentHex = theme.colorScheme.greenHex;
          dangerHex = theme.colorScheme.redHex;
          warningHex = theme.colorScheme.yellowHex;
          infoHex = theme.colorScheme.blueHex;
          successHex = theme.colorScheme.greenHex;
          specialHex = theme.colorScheme.magentaHex;

          accentRGB = theme.colorScheme.cyanRGB;
          secondaryAccentRGB = theme.colorScheme.greenRGB;
          dangerRGB = theme.colorScheme.redRGB;
          warningRGB = theme.colorScheme.yellowRGB;
          infoRGB = theme.colorScheme.blueRGB;
          successRGB = theme.colorScheme.greenRGB;
          specialRGB = theme.colorScheme.magentaRGB;

          newtForeground = "white";
          newtBackground = "black";
          newtAccent = "cyan";
        };
        borderWidth = 1;
        borderRadius = 0;
        gapsIn = 3;
        gapsOut = 5;

        fontPackage = x86Pkgs.inter;
        fontName = "Inter";
        fontSize = 11;
        fontSizeUI = 12;
        monoFontPackage = x86Pkgs.nerdfonts;
        monoFontName = "CommitMono Nerd Font";
        monoFontSize = 10;

        cursorThemePackage = x86Pkgs.simp1e-cursors;
        cursorThemeName = "Simp1e Cursors";
        cursorSize = 16;

        iconThemePackage = x86Pkgs.everforest-gtk-theme;
        iconThemeName = "Everforest-Dark-BL-LB";

        themePackage = x86Pkgs.everforest-gtk-theme;
        themeName = "Everforest-Dark-BL-LB";
        qtPlatformTheme = "gtk";
        qtStyleName = "Everforest-Dark-BL-LB";
      };

    in
    {

      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = nixosPackages;
          modules = [
            ./nixos/desktop.nix
            { nix.nixPath = [ "nixpkgs=flake:nixpkgs" ]; }
            home-manager.nixosModules.home-manager
            inputs.nix-colors.homeManagerModules.default
            {
              home-manager.extraSpecialArgs = {
                pkgs = x86Pkgs;
                device = "desktop";
                inherit inputs theme;
              };
              home-manager.users.matt = import ./home/users/matt/matt_desktop.nix;
              home-manager.backupFileExtension = "backup";
            }
          ];
        };

        thinkpad = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = nixosPackages;
          modules = [
            ./nixos/thinkpad.nix
            nixos-wsl.nixosModules.default
            { nix.nixPath = [ "nixpkgs=flake:nixpkgs" ]; }
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = {
                pkgs = x86Pkgs;
                device = "thinkpad";
                inherit inputs;
              };
              home-manager.users.matt = import ./home/users/matt/matt_thinkpad.nix;
              home-manager.backupFileExtension = "backup";
            }
          ];
        };
      };

      devShell.x86_64-linux = x86Pkgs.mkShell {
        nativeBuildInputs = [ x86Pkgs.bashInteractive ];
        buildInputs = with x86Pkgs; [
          nil
          nixpkgs-fmt
        ];
      };
    };
}
