# Home Manager module. Thin wrapper over the shared factory in lib/.
import ../lib/mk-openstarbound-module.nix {
  path = [ "home" "programs" ];
  mkConfig =
    { lib, cfg, package }:
    {
      home.packages = [ package ];

      # Optional: Create desktop file if requested
      home.file.".local/share/applications/openstarbound.desktop".text =
        lib.mkIf cfg.installDesktopFile
          ''
            [Desktop Entry]
            Name=OpenStarbound
            Exec=openstarbound
            Icon=openstarbound
            Type=Application
            Categories=Game;
            Keywords=starbound;game;multiplayer;
          '';

      # Optional: Install icon if requested
      home.file.".local/share/icons/hicolor/128x128/apps/openstarbound.png".source =
        lib.mkIf cfg.installIcon
          "${package}/share/icons/hicolor/128x128/apps/openstarbound.png";
    };
}
