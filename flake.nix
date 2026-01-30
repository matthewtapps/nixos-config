{
  description = "Matthew Tapps NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05"; # Add this

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

    sops-nix.url = "github:Mic92/sops-nix";

    # darwin.inputs.nixpkgs.follows = "nixpkgs";
    # darwin.url = "github:lnl7/nix-darwin/master";

    # impermanence.url =
    #   "github:nix-community/impermanence/63f4d0443e32b0dd7189001ee1894066765d18a5";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
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
          name = "karsa";
          system = "x86_64-linux";
          device = "karsa";
          users = {
            matt = ./home/users/matt/karsa.nix;
          };
          modules = [
            ./nixos/hosts/karsa.nix
            inputs.sops-nix.nixosModules.sops
          ];
        }
        {
          name = "mappo";
          system = "x86_64-linux";
          device = "mappo";
          users = {
            matt = ./home/users/matt/mappo.nix;
          };
          modules = [
            ./nixos/hosts/mappo.nix
            inputs.sops-nix.nixosModules.sops
          ];
        }
        {
          name = "kruppe";
          system = "x86_64-linux";
          device = "kruppe";
          users = {
            matt = ./home/users/matt/kruppe.nix;
          };
          modules = [
            ./nixos/hosts/kruppe.nix
            foundryvtt.nixosModules.foundryvtt
            inputs.sops-nix.nixosModules.sops
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
              pkgs-stable = import inputs.nixpkgs-stable {
                # Add this
                system = host.system;
                config.allowUnfree = true;
              };
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
