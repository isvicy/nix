{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable-nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
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
            stable = import stable-nixpkgs {
              inherit (prev) system;
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
