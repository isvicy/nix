{
  description = "Unified NixOS, nix-darwin, and home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    unstable-nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    clipboard-sync = {
      url = "github:dnut/clipboard-sync";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    browser-previews = {
      url = "github:nix-community/browser-previews";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    with inputs; let
      lib = nixpkgs.lib;

      nixpkgsWithOverlays = system: let
        isLinux = builtins.elem system ["x86_64-linux" "aarch64-linux"];
      in (import nixpkgs rec {
        inherit system;

        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
          ];
        };

        overlays =
          [
            (_final: prev: {
              unstable = import unstable-nixpkgs {
                system = prev.stdenv.hostPlatform.system;
                inherit config;
              };
            })
          ]
          ++ lib.optionals isLinux [
            (_final: prev: {
              confirmo = prev.callPackage ./pkgs/confirmo.nix {};
            })
            (_final: prev: {
              skim = prev.callPackage ./pkgs/skim-bin.nix {};
            })
            (_final: prev: {
              feishu = prev.feishu.overrideAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or []) ++ [prev.makeWrapper];
                postFixup =
                  (old.postFixup or "")
                  + ''
                    wrapProgram $out/opt/bytedance/feishu/feishu \
                      --add-flags "--ozone-platform=wayland --enable-wayland-ime --wayland-text-input-version=3"
                  '';
              });
            })
            (_final: prev: let
              fcitx5-qt5 = prev.libsForQt5.fcitx5-qt;
              unwrapped = prev.wechat;
            in {
              wechat = prev.symlinkJoin {
                name = "wechat-${unwrapped.version}";
                paths = [unwrapped];
                nativeBuildInputs = [prev.makeWrapper];
                postBuild = ''
                  wrapProgram $out/bin/wechat \
                    --set QT_IM_MODULE fcitx \
                    --prefix QT_PLUGIN_PATH : "$(echo ${fcitx5-qt5}/lib/qt-*/plugins)"
                '';
              };
            })
            inputs.niri.overlays.niri
          ];
      });

      configurationDefaults = args: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = args;
      };

      argDefaults = {
        inherit inputs self;
        channels = {
          inherit nixpkgs;
        };
      };

      mkNixosConfiguration = {
        system ? "x86_64-linux",
        hostname,
        username,
        args ? {},
        modules,
        homeModule,
      }: let
        specialArgs = argDefaults // {inherit hostname username system;} // args;
      in
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          pkgs = nixpkgsWithOverlays system;
          modules =
            [
              (configurationDefaults specialArgs)
              home-manager.nixosModules.home-manager
              {
                home-manager.users.${username} = import homeModule;
              }
            ]
            ++ modules;
        };

      mkDarwinConfiguration = {
        system ? "aarch64-darwin",
        hostname,
        username,
        email ? "",
        args ? {},
        modules,
        homeModule ? ./home/darwin.nix,
      }: let
        specialArgs = argDefaults // {inherit hostname username system email;} // args;
      in
        darwin.lib.darwinSystem {
          inherit system specialArgs;
          pkgs = nixpkgsWithOverlays system;
          modules =
            [
              (configurationDefaults specialArgs)
              home-manager.darwinModules.home-manager
              {
                home-manager.users.${username} = import homeModule;
              }
            ]
            ++ modules;
        };

      mkHomeConfiguration = {
        system ? "x86_64-linux",
        hostname ? null,
        username,
        args ? {},
        modules ? [],
        homeModule ? ./home/standalone.nix,
      }: let
        specialArgs =
          argDefaults
          // {inherit username system;}
          // (
            if hostname != null
            then {inherit hostname;}
            else {}
          )
          // args;
      in
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgsWithOverlays system;
          extraSpecialArgs = specialArgs;
          modules =
            [
              homeModule
            ]
            ++ modules;
        };
      # Darwin machines: hostname -> { username, email }
      # All share the same modules — only identity differs.
      # `just darwin` auto-detects hostname.
      darwinMachines = {
        "moonshotdeMacBook-Pro" = {
          username = "moonshot";
          email = "yangkai@msh.team";
        };
        "aaron-macbookair" = {
          username = "aaron";
          email = "aaron@example.com";
        };
        "metal2" = {
          username = "isvicy";
          email = "isregistermail@gmail.com";
        };
      };
    in {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;

      # NixOS hosts — each has unique hardware/modules
      nixosConfigurations.rog = mkNixosConfiguration {
        hostname = "rog";
        username = "isvicy";
        homeModule = ./hosts/rog/home.nix;
        modules = [
          clipboard-sync.nixosModules.default
          ./hosts/rog
        ];
      };

      nixosConfigurations.wsl = mkNixosConfiguration {
        hostname = "nixos-wsl";
        username = "isvicy";
        homeModule = ./hosts/wsl/home.nix;
        modules = [
          nixos-wsl.nixosModules.wsl
          ./hosts/wsl
        ];
      };

      # Darwin hosts — all share the same config, mapped by hostname
      darwinConfigurations = builtins.mapAttrs (hostname: machine:
        mkDarwinConfiguration {
          inherit hostname;
          inherit (machine) username email;
          modules = [./hosts/darwin];
        })
      darwinMachines;

      # Standalone home-manager — for plain Linux hosts (ubuntu, etc.)
      # Works from any machine: `home-manager switch --flake .#isvicy`
      homeConfigurations.isvicy = mkHomeConfiguration {
        username = "isvicy";
      };
    };
}
