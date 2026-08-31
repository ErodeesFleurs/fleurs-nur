{
  lib,
  stdenv,
  fetchzip,
}:

stdenv.mkDerivation rec {
  pname = "uudeck";
  version = "8.8.12";
  src = fetchzip {
    url = "http://uu.gdl.netease.com/uuplugin/steam-deck-plugin-x86_64/v${version}/uu.tar.gz";
    hash = "sha256-SUp8x+12/7F0ADhw0QEdMx8YHZ1nZzyU/Om3rkX7RXU=";
    stripRoot = false;
  };
  installPhase = ''
    mkdir -p $out/{share/uudeck,bin}
    mv * $out/share/uudeck
    cat > $out/bin/uudeck <<'WRAPPER'
    #!/bin/sh
    # The plugin requires a writable working directory containing its
    # uu.conf. System/root installs (Steam Deck) share /var/lib/uudeck;
    # everyone else gets a per-user XDG data directory.
    set -e
    if [ -n "$UUDECK_HOME" ]; then :
    elif [ "$(id -u)" = "0" ] || [ -w /var/lib/uudeck ]; then
      UUDECK_HOME=/var/lib/uudeck
    else
      UUDECK_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/uudeck"
    fi
    if [ ! -d "$UUDECK_HOME" ]; then
      mkdir -p "$UUDECK_HOME"
      cp "${placeholder "out"}/share/uudeck/uu.conf" "$UUDECK_HOME"/
    fi
    cd "$UUDECK_HOME"
    exec "${placeholder "out"}/share/uudeck/uuplugin" "$@"
    WRAPPER
    chmod +x $out/bin/uudeck
  '';
  meta = {
    description = "NetEase UU game accelerator plugin for Steam Deck (prebuilt x86_64 binary)";
    platforms = [ "x86_64-linux" ];
  };
}
