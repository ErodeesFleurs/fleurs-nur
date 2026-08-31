{
  description = "Fleurs's Personal NUR Repository";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
      {
      legacyPackages = forAllSystems (
        system:
        import ./default.nix {
          pkgs = nixpkgs.legacyPackages.${system};
        }
      );

      # Only derivations (buildable packages)
      packages = forAllSystems (
        system: nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) self.legacyPackages.${system}
      );

      # Overlay for integrating with nixpkgs
      overlays.default = import ./overlay.nix;

      # NixOS modules
      nixosModules = import ./modules;

      # Home Manager modules
      homeModules = import ./home-modules;
    };
}
