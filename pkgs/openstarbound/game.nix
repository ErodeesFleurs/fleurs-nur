{
  lib,
  fetchFromGitHub,
  clangStdenv,
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
  ...
}:

let
  imgui = callPackage ../imgui { };
  version = "nightly-2025-12-12";
  rev = "f0abd78";
in

clangStdenv.mkDerivation {
  pname = "openstarbound-game";
  inherit version;

  src = fetchFromGitHub {
    owner = "OpenStarbound";
    repo = "OpenStarbound";
    inherit rev;
    fetchSubmodules = false;
    # Keep the same hash as upstream packaging; update if upstream changes.
    hash = "sha256-kXAZdwppiWSbWzYsjAT+O12kVxolDwGKTGhl0YlzGfs=";
  };

  sourceRoot = "source/source";

  nativeBuildInputs = [
    cmake
    pkg-config
    imagemagick
    icoutils
  ];

  buildInputs = [
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
  ]
  ++ lib.optionals (imgui != null) [ imgui ];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
    (lib.cmakeBool "STAR_USE_JEMALLOC" true)
  ];

  postPatch = ''
    # Use repository-provided replacement CMakeLists if present; tolerate absence.
    cp ${./patches/CMakeLists.txt} CMakeLists.txt 2>/dev/null || true
    mkdir -p dist || true
  '';

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    # Basic layout for runtime files
    mkdir -p $out/libexec/openstarbound $out/share/openstarbound

    # copy build artifacts if present (some builds may place files in ../dist)
    cp -r ../dist/* $out/libexec/openstarbound/ >/dev/null 2>&1 || true

    # Ensure main binary is installed and executable
    if [ -f ../dist/starbound ]; then
      install -Dm755 ../dist/starbound $out/libexec/openstarbound/starbound
    elif [ -f $out/libexec/openstarbound/starbound ]; then
      chmod +x $out/libexec/openstarbound/starbound || true
    fi

    # Install repository-provided fallback assets (optional)
    if [ -d ../../assets ]; then
      mkdir -p $out/share/openstarbound/assets
      cp -r ../../assets/* $out/share/openstarbound/ || true
    fi

    # Install optional icon
    if [ -f ../client/icon.png ]; then
      mkdir -p $out/share/icons/hicolor/128x128/apps
      cp ../client/icon.png $out/share/icons/hicolor/128x128/apps/openstarbound.png || true
    fi

    runHook postInstall
  '';

  meta = {
    description = "OpenStarbound game build (heavy) - binaries and fallback assets";
    homepage = "https://github.com/OpenStarbound/OpenStarbound";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
