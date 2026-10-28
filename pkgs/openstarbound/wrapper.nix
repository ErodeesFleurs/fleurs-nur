{
  lib,
  callPackage,
  stdenvNoCC,
  bash,
  coreutils,
  jq,
  writeText,
  makeDesktopItem,
  python3,
  runCommand,
  mesa,
  starboundAssetsPath ? null,
  storageDir ? null,
  logDir ? null,
  modDir ? null,
  extraAssetDirs ? [ ],
  installDesktopFile ? true,
  installIcon ? true,
}:

let
  game = callPackage ./game.nix { };
  defaults = writeText "openstarbound-paths.json" (builtins.toJSON {
    inherit starboundAssetsPath storageDir logDir modDir extraAssetDirs;
  });
  desktop = makeDesktopItem {
    name = "openstarbound";
    desktopName = "OpenStarbound";
    exec = "openstarbound";
    icon = "openstarbound";
    categories = [ "Game" ];
    keywords = [ "starbound" "game" "multiplayer" ];
  };
in
stdenvNoCC.mkDerivation {
  pname = "openstarbound";
  inherit (game) version;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  strictDeps = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share"
    # Share binaries/assets instead of copying the heavy build into every override.
    ln -s ${game}/bin/* "$out/bin/"
    ln -s ${game}/share/openstarbound "$out/share/openstarbound"
    ln -s ${game}/share/doc "$out/share/doc"
    for binary in starbound starbound_server; do
      install -m755 ${./launcher.sh} "$out/bin/$binary"
      substituteInPlace "$out/bin/$binary" \
        --replace-fail '@bash@' '${bash}/bin/bash' \
        --replace-fail '@runtimePath@' '${lib.makeBinPath [ coreutils jq ]}' \
        --replace-fail '@defaults@' '${defaults}' \
        --replace-fail '@game@' '${game}'
    done
    ln -s starbound "$out/bin/openstarbound"
    ${lib.optionalString installDesktopFile ''
      ln -s ${desktop}/share/applications "$out/share/applications"
    ''}
    ${lib.optionalString installIcon ''
      install -Dm644 ${game.src}/source/client/openstarbound.png \
        "$out/share/icons/hicolor/256x256/apps/openstarbound.png"
    ''}
    runHook postInstall
  '';

  passthru = {
    heavy = game;
    tests.launcher = runCommand "openstarbound-launcher-tests" {
      nativeBuildInputs = [ python3 ];
    } ''
      python ${./test-launcher.py} ${./launcher.sh} \
        ${bash}/bin/bash ${lib.makeBinPath [ coreutils jq ]}
      touch "$out"
    '';
    tests.driver-initialization = runCommand "openstarbound-driver-initialization" { } ''
      export HOME="$TMPDIR"
      ${game}/libexec/starbound -version > baseline
      # Force the real GLX vendor/LLVM initialization, without a display or
      # commercial assets. Previously this crashed before main with SIGSEGV.
      env __GLX_VENDOR_LIBRARY_NAME=mesa LD_LIBRARY_PATH=${lib.getLib mesa}/lib \
        ${game}/libexec/starbound -version > actual
      cmp baseline actual
      cp actual "$out"
    '';
  };
  meta = game.meta // {
    description = "OpenStarbound client, server and tools with configurable runtime paths";
    mainProgram = "openstarbound";
  };
}
