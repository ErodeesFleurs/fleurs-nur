# Example flake.nix; add your host hardware and boot configuration before use.
{
  description = "NixOS and Home Manager Asterbound examples";

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
      allowAsterbound = p:
        builtins.elem (nixpkgs.lib.getName p) [ "asterbound" "openstarbound-sdks" ];
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = allowAsterbound;
        overlays = [ fleurs-nur.overlays.default ];
      };
    in {
      nixosConfigurations = {
        my-desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            fleurs-nur.nixosModules.asterbound
            {
              nixpkgs.config.allowUnfreePredicate = allowAsterbound;
              programs.asterbound = {
                enable = true;
                starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
                # Null writable paths use independent XDG_DATA_HOME/asterbound directories.
                # storageDir = "/mnt/games/asterbound/storage";
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
              nixpkgs.config.allowUnfreePredicate = allowAsterbound;
              nixpkgs.overlays = [ fleurs-nur.overlays.default ];
              environment.systemPackages = [
                (pkgs.asterbound.override {
                  starboundAssetsPath = "$HOME/Games/Starbound/assets";
                  storageDir = "$XDG_DATA_HOME/asterbound/storage";
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
              nixpkgs.config.allowUnfreePredicate = allowAsterbound;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.alice = {
                imports = [ fleurs-nur.homeModules.asterbound ];
                home.username = "alice";
                home.homeDirectory = "/home/alice";
                # Choose this for your existing Home Manager installation.
                home.stateVersion = "25.11";
                home.programs.asterbound = {
                  enable = true;
                  extraAssetDirs = [ "$HOME/asterbound/workshop-content" ];
                };
              };
            }
          ];
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.asterbound ];
      };
    };
}
