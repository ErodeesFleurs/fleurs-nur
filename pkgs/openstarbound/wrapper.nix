{
  lib,
  makeWrapper,
  clangStdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  imagemagick,
  icoutils,
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
  callPackage,
  # optional overrides for paths
  starboundAssetsPath ? null,
  storageDir ? null,
  logDir ? null,
  modDir ? null,
  extraAssetDirs ? [ ],
  ...
}:

let
  version = "nightly-2025-12-12";

  # Import the heavy build (game.nix) from the same directory. The importer
  # may pass through the same set of build inputs so the heavy derivation
  # is constructed consistently.
  game = import ./game.nix {
    inherit
      lib
      fetchFromGitHub
      callPackage
      clangStdenv
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

clangStdenv.mkDerivation {
  pname = "openstarbound";
  inherit version;
  src = null;
  doUnpack = false;
  unpackPhase = ":";

  nativeBuildInputs = [ makeWrapper ];
  # declare the heavy build as a build input so Nix will build it first and
  # make its outputs available for copying into this wrapper's $out.
  buildInputs = [ game ];

  installPhase = ''
        runHook preInstall

        mkdir -p $out/bin $out/libexec/openstarbound $out/share/openstarbound

        # copy runtime outputs (binaries + fallback assets) from heavy build
        cp -r ${game}/libexec/openstarbound $out/libexec/ || true
        cp -r ${game}/share/openstarbound $out/share/ || true

        # write build-time defaults for runtime wrapper (if any) into libexec
        cat > $out/libexec/openstarbound/wrapper-build-defaults <<'NIXV'
        STARBOUND_ASSETS_NIX='${if starboundAssetsPath != null then starboundAssetsPath else ""}'
        STORAGE_DIR_NIX='${if storageDir != null then storageDir else ""}'
        LOG_DIR_NIX='${if logDir != null then logDir else ""}'
        MOD_DIR_NIX='${if modDir != null then modDir else ""}'
        EXTRA_ASSET_DIRS_NIX='${lib.concatStringsSep ":" extraAssetDirs}'
    NIXV
            # write a small runtime wrapper script that composes a boot config at run-time
            cat > $out/bin/openstarbound <<'SH'
            #!/bin/sh -e

            # Resolve this script's prefix in the Nix store so we can find sibling libexec/share
            SELF=$(readlink -f "$0")
            BIN_DIR=$(dirname "$SELF")
            PREFIX=$(dirname "$BIN_DIR")

            STARBOUND_BIN="$PREFIX/libexec/openstarbound/starbound"
            FALLBACK_ASSETS="$PREFIX/share/openstarbound/assets"

            # XDG defaults
            if [ -z "$XDG_DATA_HOME" ]; then
              XDG_DATA_HOME="$HOME/.local/share"
            fi
            if [ -z "$XDG_CONFIG_HOME" ]; then
              XDG_CONFIG_HOME="$HOME/.config"
            fi

            # Load build-time injected defaults if present (packager can set these)
            if [ -f "$PREFIX/libexec/openstarbound/wrapper-build-defaults" ]; then
              . "$PREFIX/libexec/openstarbound/wrapper-build-defaults"
            fi

            # Compute runtime storage/log/mod directories (build-time overrides win)
            if [ -n "$STORAGE_DIR_NIX" ]; then
              STORAGE_DIR="$STORAGE_DIR_NIX"
            else
              STORAGE_DIR="$XDG_DATA_HOME/OpenStarbound/storage"
            fi

            if [ -n "$LOG_DIR_NIX" ]; then
              LOG_DIR="$LOG_DIR_NIX"
            else
              LOG_DIR="$XDG_DATA_HOME/OpenStarbound/logs"
            fi

            if [ -n "$MOD_DIR_NIX" ]; then
              MOD_DIR="$MOD_DIR_NIX"
            else
              MOD_DIR="$XDG_DATA_HOME/OpenStarbound/mods"
            fi

            mkdir -p "$STORAGE_DIR" "$LOG_DIR" "$MOD_DIR"
            BOOT_CONFIG=$(mktemp -t openstarbound-boot.XXXXXXXXXX.json)
            trap 'rm -f "$BOOT_CONFIG"' EXIT

            # Assemble asset directories (runtime precedence: env STARBOUND_ASSETS, user mods, build-time extraAssetDirs, packaged fallback)
            ASSETS_JSON=""
            if [ -n "$STARBOUND_ASSETS" ]; then
              ASSETS_JSON="$ASSETS_JSON\"$STARBOUND_ASSETS\","
            fi

            if [ -n "$MOD_DIR" ]; then
              ASSETS_JSON="$ASSETS_JSON\"$MOD_DIR\","
            fi

            # inject extra asset dirs from package (colon-separated list)
            if [ -n "$EXTRA_ASSET_DIRS_NIX" ]; then
              OLD_IFS="$IFS"; IFS=":"; for d in $EXTRA_ASSET_DIRS_NIX; do
                if [ -n "$d" ]; then ASSETS_JSON="$ASSETS_JSON\"$d\","; fi
              done; IFS="$OLD_IFS"
            fi

            ASSETS_JSON="$ASSETS_JSON\"$FALLBACK_ASSETS\""
            ASSETS_JSON="$(echo "$ASSETS_JSON" | sed 's/,$//')"

            cat > "$BOOT_CONFIG" <<JSON
            {
              "assetDirectories": [ $ASSETS_JSON ],
              "storageDirectory": "$STORAGE_DIR",
              "logDirectory": "$LOG_DIR"
            }
    JSON

            # Support helper flag that prints the generated boot config
            for a in "$@"; do
              if [ "$a" = "--print-bootconfig" ]; then
                cat "$BOOT_CONFIG"
                exit 0
              fi
            done

            exec "$STARBOUND_BIN" -bootconfig "$BOOT_CONFIG" "$@"
    SH
                chmod +x $out/bin/openstarbound

                runHook postInstall
  '';

  meta = {
    description = "OpenStarbound wrapper (light) depending on separate game build";
    platforms = lib.platforms.linux;
  };

  passthru = {
    # expose the heavy derivation so callers can build it directly:
    heavy = game;
  };
}
