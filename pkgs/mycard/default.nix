{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "mycard";
  version = "3.0.36";
  src = fetchurl {
    url = "https://github.com/mycard/moecube/releases/download/${version}/mycard-${version}-x86_64.AppImage";
    hash = "sha256-YzZNN8YIQJnlqeGoYxqNWJ8jHISO2NP7anWYgzArYQA=";
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # The AppImage ships a desktop entry with Exec=AppRun and a 512x512 icon;
  # install both with the Exec line pointed at the wrapped launcher.
  extraInstallCommands = ''
    install -Dm644 ${appimageContents}/mycard.desktop $out/share/applications/mycard.desktop
    substituteInPlace $out/share/applications/mycard.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=mycard'
    install -Dm644 ${appimageContents}/usr/share/icons/hicolor/512x512/apps/mycard.png \
      $out/share/icons/hicolor/512x512/apps/mycard.png
  '';

  meta = with lib; {
    description = "MyCard launcher for Yu-Gi-Oh! and other games";
    homepage = "https://mycard.world";
    platforms = [ "x86_64-linux" ];
    mainProgram = "mycard";
  };
}
