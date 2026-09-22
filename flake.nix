{
  description = "Matthew Tapps NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    foundryvtt.url = "github:reckenrode/nix-foundryvtt";
    foundryvtt.inputs.nixpkgs.follows = "nixpkgs";

    matugen.url = "github:InioX/matugen?ref=v2.2.0";
    matugen.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-cowork.url = "github:johnzfitch/claude-cowork-linux";

    claude-code.url = "github:sadjow/claude-code-nix";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";

    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    todone = {
      url = "github:matthewtapps/todone";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lsag-quartermaster = {
      url = "git+ssh://git@github.com/matthewtapps/lsag-quartermaster.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      foundryvtt,
      stylix,
      ...
    }@inputs:
    let
      overlays = [
        # Swap pkgs.claude-code to the independently-tracked flake (see input).
        inputs.claude-code.overlays.default
        (final: prev: {
          zen-browser = inputs.zen-browser.packages.${final.stdenv.hostPlatform.system}.default;
        })
        # Ruby sass gem is broken (no bin/); replace with dart-sass for stylix gnome shell theme
        (final: prev: {
          sass = final.dart-sass;
        })
        # wf-recorder 0.6.0 reads AVCodec::pix_fmts, sample_fmts and ch_layouts,
        # which ffmpeg 9 removed. Arch carries the port to
        # avcodec_get_supported_config; upstream has none.
        (final: prev: {
          wf-recorder = prev.wf-recorder.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              (final.fetchpatch {
                url = "https://gitlab.archlinux.org/archlinux/packaging/packages/wf-recorder/-/raw/d85efa2704043e629f2c47002fea6f98b02ee497/ffmpeg-9.patch";
                hash = "sha256-TSvBUARw9Qva2yZp7YeKr4jw5hi69wog/rsE5TRh5G4=";
              })
            ];
          });
        })
        # GitLab regenerated the wireshark v4.6.5 archive tarball, so the hash
        # locked in nixpkgs does not match what GitLab serves. This pins the
        # current upstream hash.
        (final: prev: {
          wireshark = prev.wireshark.overrideAttrs (old: {
            src = prev.fetchFromGitLab {
              repo = "wireshark";
              owner = "wireshark";
              tag = "v${old.version}";
              hash = "sha256-Zvrwxjp4LK2J3QnxmPxKKrU01YHQvPyp54UWzeGNCjA=";
            };
          });
        })
      ];

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
        {
          name = "tehol";
          system = "x86_64-linux";
          device = "tehol";
          users = {
            matt = ./home/users/matt/tehol.nix;
          };
          modules = [
            ./nixos/hosts/tehol.nix
            inputs.sops-nix.nixosModules.sops
          ];
        }
        {
          name = "baruk";
          system = "x86_64-linux";
          device = "baruk";
          users = {
            matt = ./home/users/matt/baruk.nix;
          };
          modules = [
            ./nixos/hosts/baruk.nix
            inputs.sops-nix.nixosModules.sops
          ];
        }
        {
          name = "samar";
          system = "x86_64-linux";
          device = "samar";
          users = {
            matt = ./home/users/matt/samar.nix;
          };
          modules = [
            ./nixos/hosts/samar.nix
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
            specialArgs = {
              inherit inputs host;
            };
            modules = host.modules ++ [
              inputs.stylix.nixosModules.stylix
              {
                nixpkgs.hostPlatform = host.system;
                nixpkgs.config.allowUnfree = true;
                nixpkgs.overlays = overlays;
              }
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  # home.packages go to the home-manager profile so hmswitch can
                  # install and remove them without a system switch.
                  useUserPackages = false;
                  backupFileExtension = "bak";
                  extraSpecialArgs = {
                    inherit inputs host;
                    device = host.device;
                  };
                  sharedModules = [ inputs.noctalia.homeModules.default ];
                  users = builtins.mapAttrs (_: file: { imports = [ file ]; }) host.users;
                };
              }
            ];
          };
        }) hosts
      )
      // {
        installer = nixpkgs.lib.nixosSystem {
          modules = [
            ./nixos/installer/dl380p.nix
            { nixpkgs.hostPlatform = "x86_64-linux"; }
          ];
        };
      };

      deploy = {
        remoteBuild = true;
        nodes = builtins.listToAttrs (
          map (host: {
            name = host.name;
            value = {
              hostname = host.name;
              profiles.system = {
                sshUser = "root";
                magicRollback = true;
                # A laptop finishing activation over wifi does not always
                # confirm inside the 30 second default, and missing it rolls a
                # good deploy back.
                confirmTimeout = 120;
                path =
                  inputs.deploy-rs.lib.${host.system}.activate.nixos
                    self.nixosConfigurations.${host.name};
              };
            };
          }) (builtins.filter (h: h.name != "karsa") hosts)
        );
      };

      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" ] (_: {
        installer-iso = self.nixosConfigurations.installer.config.system.build.isoImage;
      });

      checks = builtins.mapAttrs (_: lib: lib.deployChecks self.deploy) inputs.deploy-rs.lib;

      templates = {
        devshell = {
          path = ./templates/devshell;
          description = "Minimal devShell; drop packages into the array";
        };
        default = self.templates.devshell;
      };
    };
}
