# Example flake.nix; add your host hardware and boot configuration before use.
{
  description = "NixOS and Home Manager OpenStarbound examples";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fleurs-nur = {
      url = "github:ErodeesFleurs/fleurs-nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, fleurs-nur, home-manager, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations = {
        my-desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            fleurs-nur.nixosModules.openstarbound
            {
              programs.openstarbound = {
                enable = true;
                starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
                # Null writable paths preserve XDG_DATA_HOME/OpenStarbound.
                # storageDir = "/mnt/games/OpenStarbound/storage";
                installDesktopFile = true;
                installIcon = true;
              };
            }
          ];
        };

        with-overlay = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ pkgs, ... }: {
              nixpkgs.overlays = [ fleurs-nur.overlays.default ];
              environment.systemPackages = [
                (pkgs.openstarbound.override {
                  starboundAssetsPath = "$HOME/Games/Starbound/assets";
                  storageDir = "$XDG_DATA_HOME/OpenStarbound/storage";
                })
              ];
            })
          ];
        };

        with-home-manager = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.alice = {
                imports = [ fleurs-nur.homeModules.openstarbound ];
                home.username = "alice";
                home.homeDirectory = "/home/alice";
                # Choose this for your existing Home Manager installation.
                home.stateVersion = "25.11";
                home.programs.openstarbound = {
                  enable = true;
                  extraAssetDirs = [ "$HOME/OpenStarbound/workshop-content" ];
                };
              };
            }
          ];
        };
      };

      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = [ fleurs-nur.packages.${system}.openstarbound ];
      };
    };
}
