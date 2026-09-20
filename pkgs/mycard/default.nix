{
  lib,
  appimageTools,
  fetchurl,
  writeText,
}:

let
  pname = "mycard";
  version = "3.0.87";
  src = fetchurl {
    # cdntx2.moecube.com 301-redirects here; fetching the mirror directly keeps
    # nix from stalling on that redirect (same file, same hash).
    url = "https://cdncf.moecube.com/downloads/MyCard-${version}.AppImage";
    hash = "sha256-2R+tz8NuSPq5MnFLH0y1CTh4bDz4l7WMzoKz7IRfYJ8=";
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };

  # Noto Sans/Serif CJK 2.004 are CFF2 *variable* collections: fontconfig hands
  # Chromium an FC_INDEX that encodes the named instance (e.g. 262146 = 4<<16|2),
  # and the FreeType/Skia bundled with this 2019-era Electron cannot load such a
  # face -- every CJK glyph then renders as a tofu box ("黑框").  Reject the
  # variable files inside the sandbox so the static CJK fonts that load fine
  # (Sarasa Gothic, Source Han Sans, WenQuanYi) win, and keep the Windows/macOS
  # CJK family names the launcher pages ask for pointing at them.
  fontconfig = writeText "mycard-fontconfig.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <include>/etc/fonts/fonts.conf</include>

      <selectfont>
        <rejectfont>
          <glob>*NotoSansCJK-VF.otf.ttc</glob>
          <glob>*NotoSerifCJK-VF.otf.ttc</glob>
        </rejectfont>
      </selectfont>

      <alias binding="strong">
        <family>Microsoft YaHei</family>
        <prefer><family>Sarasa Gothic SC</family></prefer>
      </alias>
      <alias binding="strong">
        <family>PingFang SC</family>
        <prefer><family>Sarasa Gothic SC</family></prefer>
      </alias>
      <alias binding="strong">
        <family>Hiragino Sans GB</family>
        <prefer><family>Sarasa Gothic SC</family></prefer>
      </alias>
      <alias binding="strong">
        <family>Microsoft JhengHei</family>
        <prefer><family>Sarasa Gothic TC</family></prefer>
      </alias>
    </fontconfig>
  '';
in
appimageTools.wrapType2 {
  inherit pname version src;

  # 3.0.87 ships its own Linux tooling in resources/bin (aria2c, tar, zstd), but
  # the launcher's game manifests run Windows executables through a bare `wine`
  # (tools/patch-linux-wine sets action.interpreter = 'wine' for linux).  The FHS
  # sandbox only sees the environment it builds, so wine has to come from here.
  extraPkgs = pkgs: [ pkgs.wineWow64Packages.stable ];

  # Point fontconfig at the overrides above; it includes the host's fonts.conf,
  # so font availability is unchanged apart from the rejected variable fonts.
  #
  # NODE_ENV=production is part of the fix, not cosmetics: the download code
  # (app/download.service.ts getAria2cPath) picks resources/bin/aria2c only when
  # process.env.NODE_ENV === 'production' and otherwise resolves the *relative*
  # "bin/aria2c" against the cwd.  The main process sets NODE_ENV itself, but
  # renderers inherit the env of the zygote (forked before index.js runs), so
  # without this the renderer sees NODE_ENV unset -> spawn ENOENT -> Electron
  # reports "aria2c exited with code -2" and every download fails.
  extraBwrapArgs = [
    "--setenv"
    "FONTCONFIG_FILE"
    "${fontconfig}"
    "--setenv"
    "NODE_ENV"
    "production"
    # The bundled aria2c statically links OpenSSL, whose compiled-in trust store
    # is /etc/ssl/cert.pem + the (unhashed) /etc/ssl/certs directory; neither
    # works here, so every HTTPS download died with "SSL/TLS handshake failure:
    # unable to get local issuer certificate".  Point OpenSSL at the bundle the
    # FHS env already mounts.
    "--setenv"
    "SSL_CERT_FILE"
    "/etc/ssl/certs/ca-certificates.crt"
  ];

  # The AppImage ships a desktop entry (Exec=AppRun --no-sandbox %U) and a
  # 512x512 icon; install both with the Exec line pointed at the wrapped
  # launcher.
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
