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

    # hyprland deliberately does not follow nixpkgs: it caches binaries on
    # hyprland.cachix.org built against the nixpkgs it pins. Following unstable
    # would miss that cache and force a full source rebuild. Same rationale as
    # claude-code below.
    hyprland.url = "github:hyprwm/Hyprland";

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Independently-bumpable Claude Code (hourly npm tracking, prebuilt via
    # claude-code.cachix.org). Overlay sets pkgs.claude-code, which the whole
    # node-wrapper / ahvi / home / packages chain inherits. Deliberately does not
    # follow nixpkgs: the flake pins Node 22 and caches binaries
    # against its locked nixpkgs; following unstable would force a source
    # rebuild. Bump with `nix flake update claude-code`.
    claude-code.url = "github:sadjow/claude-code-nix";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";

    # The cachix branch is the one published to noctalia.cachix.org. This input
    # deliberately does not follow nixpkgs: it keeps the nixpkgs upstream pins so
    # the published binaries match. Following unstable would compile the C++
    # shell on every host. Same rationale as hyprland and claude-code above.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    todone = {
      url = "github:matthewtapps/todone";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # No remote exists for this repo, so it is read from the laptop clone. The
    # ref keeps the working copy out: a deploy carries the last commit on main.
    lsag-quartermaster = {
      url = "git+file:///home/matt/dev/lsag-quartermaster?ref=main";
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

      config = {
        allowUnfree = true;
      };

      mkPkgs =
        system:
        import nixpkgs {
          localSystem = system;
          inherit config overlays;
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
                    claude-desktop = inputs.claude-desktop.packages.${host.system}.claude-desktop-with-fhs;
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

      # ahvi-aware `claude` launchers for the ~/cs work devshell to hand to
      # slop-cop's mkClaudeWrapper (which execs `${claude-code}/bin/claude`), so
      # slop-cop-wrapped harnesses keep the ahvi MCP. Work machines only (samar,
      # tehol) reach ahvi over the WireGuard VPN host, so the work profile is
      # pinned to it here; both inner binaries are named `claude`.
      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" ] (
        system:
        let
          pkgs = mkPkgs system;
          ahvi = import ./nixos/packages/claude-ahvi.nix { inherit pkgs; };
          ep = ahvi.mkEndpoints "10.88.88.131";
        in
        {
          claude-ahvi-work = ahvi.mkWrapper { apiUrl = ep.work.api; };
          claude-ahvi-personal = ahvi.mkWrapper {
            apiUrl = ep.personal.api;
            configSubdir = ".claude-alt";
          };

          installer-iso = self.nixosConfigurations.installer.config.system.build.isoImage;
        }
      );

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
