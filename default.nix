# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (pkgs) lib;

  # Auto-discover all packages in pkgs/ directory
  # Each subdirectory with a default.nix is treated as a package
  discoverPackages =
    let
      pkgsDir = ./pkgs;
      entries = builtins.readDir pkgsDir;

      # Filter to only directories that contain default.nix
      validPackages = lib.filterAttrs (
        name: type: type == "directory" && builtins.pathExists (pkgsDir + "/${name}/default.nix")
      ) entries;

      # Create attrset of packages by calling each with callPackage
      packageSet = lib.mapAttrs (name: _: pkgs.callPackage (pkgsDir + "/${name}") { }) validPackages;
    in
    packageSet;

in
discoverPackages
// {
  # The `modules` and `homeModules` names are special (not packages);
  # everything else is auto-discovered from pkgs/ above.
  modules = import ./modules;
  homeModules = import ./home-modules;
}
