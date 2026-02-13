{
  lib,
  fetchFromGitHub,
  callPackage,
  clangStdenv,
  cmake,
  pkg-config,
  imagemagick,
  icoutils,
  makeWrapper,
  zlib,
  zstd,
  libsm,
  libxi,
  glew,
  libpng,
  jemalloc,
  freetype,
  libvorbis,
  libopus,
  sdl3,
  re2,
  cpptrace,
  libcpr,
  # Optional path configurations
  starboundAssetsPath ? null,
  storageDir ? null,
  logDir ? null,
  modDir ? null,
  extraAssetDirs ? [ ],
}:

let
  # Import the lightweight wrapper which in turn imports the heavy `game.nix`.
  # We forward the common build inputs so the imported files construct their
  # derivations using the same package set.
  wrapper = import ./wrapper.nix {
    inherit
      lib
      makeWrapper
      clangStdenv
      callPackage
      fetchFromGitHub
      cmake
      pkg-config
      imagemagick
      icoutils
      zlib
      zstd
      libsm
      libxi
      glew
      libpng
      jemalloc
      freetype
      libvorbis
      libopus
      sdl3
      re2
      cpptrace
      libcpr
      ;
    inherit
      starboundAssetsPath
      storageDir
      logDir
      modDir
      extraAssetDirs
      ;
  };
in
# Export the wrapper derivation as the package. The wrapper provides
# `passthru.heavy` (the heavy `game` derivation) so callers can build the
# full game when needed (e.g. `pkgs.openstarbound.passthru.heavy`).
wrapper
