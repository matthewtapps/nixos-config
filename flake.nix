{
  description = "Matthew Tapps NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    matugen.url = "github:InioX/matugen?ref=v2.2.0";

    lan-mouse.url = "github:feschber/lan-mouse";

    hyprland.url = "github:hyprwm/Hyprland";

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
      zen-browser,
      ...
    }@inputs:
    let
      overlays = [ inputs.neovim-nightly-overlay.overlays.default ];

      config = {
        allowUnfree = true;
      };

      nixosPackages = import nixos {
        system = "x86_64-linux";
        inherit config zen-browser overlays;
      };

      x86Pkgs = import nixpkgs {
        system = "x86_64-linux";
        inherit config zen-browser overlays;
      };

    in
    {

      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = nixosPackages;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./nixos/desktop.nix
            { nix.nixPath = [ "nixpkgs=flake:nixpkgs" ]; }
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = {
                pkgs = x86Pkgs;
                device = "desktop";
                inherit
                  inputs
                  ;
              };
              home-manager.users.matt = import ./home/users/matt/matt_desktop.nix;
              home-manager.backupFileExtension = "backup";
            }
          ];
        };

        nuc = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = nixosPackages;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./nixos/nuc.nix
            { nix.nixPath = [ "nixpkgs=flake:nixpkgs" ]; }
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = {
                pkgs = x86Pkgs;
                device = "nuc";
                inherit
                  inputs
                  ;
              };
              home-manager.users.matt = import ./home/users/matt/nuc.nix;
              home-manager.users.anna = import ./home/users/anna/nuc.nix;
              home-manager.backupFileExtension = "backup";
            }
          ];
        };

        thinkpad-wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = nixosPackages;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./nixos/thinkpad-wsl.nix
            nixos-wsl.nixosModules.default
            { nix.nixPath = [ "nixpkgs=flake:nixpkgs" ]; }
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = {
                pkgs = x86Pkgs;
                device = "thinkpad-wsl";
                inherit inputs;
              };
              home-manager.users.matt = import ./home/users/matt/matt_thinkpad-wsl.nix;
              home-manager.backupFileExtension = "backup";
            }
          ];
        };

        thinkpad = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = nixosPackages;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./nixos/thinkpad.nix
            { nix.nixPath = [ "nixpkgs=flake:nixpkgs" ]; }
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = {
                pkgs = x86Pkgs;
                device = "thinkpad";
                inherit
                  inputs
                  ;
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
