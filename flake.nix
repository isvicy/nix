{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    unstable-nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      # Pin to last working version - newer versions have a bug with .makeWrapper syntax
      url = "github:AvengeMedia/DankMaterialShell/1f2a1c5dec5c36264e24d185f38fab2a7ddbb185";
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
  };

  outputs = inputs:
    with inputs; let
      nixpkgsWithOverlays = system: (import nixpkgs rec {
        inherit system;

        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
          ];
        };

        overlays = [
          (_final: prev: {
            unstable = import unstable-nixpkgs {
              system = prev.stdenv.hostPlatform.system;
              inherit config;
            };
          })
          inputs.niri.overlays.niri # for using niri unstable
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
              clipboard-sync.nixosModules.default
              {
                home-manager.users.${username} = import ./users/${username}/home.nix;
              }
            ]
            ++ modules;
        };

      # For generic Linux home-manager configurations
      mkHomeConfiguration = {
        system ? "x86_64-linux",
        hostname ? null,
        username,
        args ? {},
        modules,
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
          modules = [
            ./users/${username}/home.nix
          ];
        }
        ++ modules;
    in {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

      nixosConfigurations.rog = mkNixosConfiguration {
        hostname = "rog";
        username = "isvicy";
        modules = [
          ./hosts/rog
        ];
      };

      homeConfigurations.isvicy = mkHomeConfiguration {
        username = "isvicy";
      };
    };
}
