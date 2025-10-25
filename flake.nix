{
  description = "Matthew Tapps NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    foundryvtt.url = "github:reckenrode/nix-foundryvtt";

    matugen.url = "github:InioX/matugen?ref=v2.2.0";

    lan-mouse.url = "github:feschber/lan-mouse";

    hyprland.url = "github:hyprwm/Hyprland";

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # darwin.inputs.nixpkgs.follows = "nixpkgs";
    # darwin.url = "github:lnl7/nix-darwin/master";

    # impermanence.url =
    #   "github:nix-community/impermanence/63f4d0443e32b0dd7189001ee1894066765d18a5";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixos-wsl,
      foundryvtt,
      stylix,
      ...
    }@inputs:
    let
      overlays = [
        inputs.neovim-nightly-overlay.overlays.default
        (final: prev: {
          zen-browser = inputs.zen-browser.packages.${final.system}.default;
        })
      ];

      config = {
        allowUnfree = true;
      };

      mkPkgs =
        system:
        import nixpkgs {
          inherit system config overlays;
        };

      hosts = [
        {
          name = "desktop";
          system = "x86_64-linux";
          device = "desktop";
          users = {
            matt = ./home/users/matt/desktop.nix;
          };
          modules = [
            ./nixos/hosts/desktop.nix
            foundryvtt.nixosModules.foundryvtt
          ];
        }
        {
          name = "thinkpad";
          system = "x86_64-linux";
          device = "thinkpad";
          users = {
            matt = ./home/users/matt/thinkpad.nix;
          };
          modules = [
            ./nixos/hosts/thinkpad.nix
          ];
        }
        {
          name = "nuc";
          system = "x86_64-linux";
          device = "nuc";
          users = {
            matt = ./home/users/matt/nuc.nix;
            anna = ./home/users/anna/nuc.nix;
          };
          modules = [
            ./nixos/hosts/nuc.nix
          ];
        }
        {
          name = "thinkpad-wsl";
          system = "x86_64-linux";
          device = "thinkpad-wsl";
          users = {
            matt = ./home/users/matt/matt_thinkpad-wsl.nix;
          };
          modules = [
            ./nixos/hosts/thinkpad-wsl.nix
            nixos-wsl.nixosModules.default
          ];
        }
      ];
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        map (host: {
          name = host.name;
          value = nixpkgs.lib.nixosSystem {
            system = host.system;
            specialArgs = {
              inherit inputs host;
              mypkgs = mkPkgs host.system;
            };
            modules = host.modules ++ [ inputs.stylix.nixosModules.stylix ];
          };

        }) hosts
      );

      homeConfigurations = builtins.listToAttrs (
        builtins.concatLists (
          map (
            host:
            let
              pkgs = mkPkgs host.system;
            in
            builtins.attrValues (
              builtins.mapAttrs (username: file: {
                name = "${username}@${host.name}";
                value = home-manager.lib.homeManagerConfiguration {
                  inherit pkgs;
                  extraSpecialArgs = {
                    inherit inputs host;
                    device = host.device;
                    claude-desktop = inputs.claude-desktop.packages.${host.system}.claude-desktop-with-fhs;
                  };
                  modules = [
                    file
                    inputs.stylix.homeModules.stylix
                    {
                      home.homeDirectory = "/home/${username}";
                      home.username = username;
                    }
                  ];
                };
              }) host.users
            )

          ) hosts
        )
      );
    };
}
