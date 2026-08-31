{
  callPackage,
  # Optional path configurations
  starboundAssetsPath ? null,
  storageDir ? null,
  logDir ? null,
  modDir ? null,
  extraAssetDirs ? [ ],
}:

# Route through callPackage so nixpkgs injects every build input
# automatically; the wrapper in turn builds the heavy game derivation.
callPackage ./wrapper.nix {
  inherit starboundAssetsPath storageDir logDir modDir extraAssetDirs;
}
