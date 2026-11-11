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
  defaults = writeText "asterbound-paths.json" (builtins.toJSON {
    inherit starboundAssetsPath storageDir logDir modDir extraAssetDirs;
  });
  desktop = makeDesktopItem {
    name = "asterbound";
    desktopName = "Asterbound";
    exec = "asterbound";
    icon = "asterbound";
    categories = [ "Game" ];
    keywords = [ "starbound" "game" "multiplayer" ];
  };
in
stdenvNoCC.mkDerivation {
  pname = "asterbound";
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
    ln -s ${game}/share/asterbound "$out/share/asterbound"
    ln -s ${game}/share/doc "$out/share/doc"
    for binary in asterbound asterbound_server; do
      install -m755 ${./launcher.sh} "$out/bin/$binary"
      substituteInPlace "$out/bin/$binary" \
        --replace-fail '@bash@' '${bash}/bin/bash' \
        --replace-fail '@runtimePath@' '${lib.makeBinPath [ coreutils jq ]}' \
        --replace-fail '@defaults@' '${defaults}' \
        --replace-fail '@game@' '${game}'
    done
    ${lib.optionalString installDesktopFile ''
      ln -s ${desktop}/share/applications "$out/share/applications"
    ''}
    ${lib.optionalString installIcon ''
      # The ICO contains separately drawn small ASCII icons, not downscaled
      # copies of the 1024px application PNG.
      ${python3.withPackages (p: [ p.pillow ])}/bin/python3 - \
        ${game.src}/source/client/asterbound.ico "$out/share/icons/hicolor" <<'PY'
      from pathlib import Path
      import sys
      from PIL import Image

      with Image.open(sys.argv[1]) as icon:
          for width, height in sorted(icon.ico.sizes()):
              directory = Path(sys.argv[2]) / f"{width}x{height}" / "apps"
              directory.mkdir(parents=True, exist_ok=True)
              icon.ico.getimage((width, height)).save(directory / "asterbound.png")
      PY
    ''}
    runHook postInstall
  '';

  passthru = {
    heavy = game;
    tests.launcher = runCommand "asterbound-launcher-tests" {
      nativeBuildInputs = [ python3 ];
    } ''
      python ${./test-launcher.py} ${./launcher.sh} \
        ${bash}/bin/bash ${lib.makeBinPath [ coreutils jq ]}
      touch "$out"
    '';
    tests.driver-initialization = runCommand "asterbound-driver-initialization" { } ''
      export HOME="$TMPDIR"
      ${game}/libexec/asterbound -version > baseline
      # Force the real GLX vendor/LLVM initialization, without a display or
      # commercial assets. Previously this crashed before main with SIGSEGV.
      env __GLX_VENDOR_LIBRARY_NAME=mesa LD_LIBRARY_PATH=${lib.getLib mesa}/lib \
        ${game}/libexec/asterbound -version > actual
      cmp baseline actual
      cp actual "$out"
    '';
  };
  meta = game.meta // {
    description = "Asterbound client, server and tools with configurable runtime paths";
    mainProgram = "asterbound";
  };
}
