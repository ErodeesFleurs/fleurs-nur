{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.openstarbound;
  starboundAssetsPath = cfg.starboundAssetsPath;
  storageDir = cfg.storageDir;
  logDir = cfg.logDir;
  modDir = cfg.modDir;
  extraAssetDirs = cfg.extraAssetDirs;
  openstarboundPackage =
    if cfg.package != null then
      cfg.package
    else
      pkgs.callPackage ../pkgs/openstarbound {
        inherit
          starboundAssetsPath
          storageDir
          logDir
          modDir
          extraAssetDirs
          ;
      };

in
{
  options.programs.openstarbound = {
    enable = mkEnableOption "OpenStarbound, an open-source Starbound client with improvements";

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = literalExpression "pkgs.openstarbound";
      description = ''
        The OpenStarbound package to use. If null, a package will be built
        with the configured paths.
      '';
    };

    starboundAssetsPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
      description = ''
        Path to Starbound's official game assets.

        Common locations:
        - Steam: $HOME/.local/share/Steam/steamapps/common/Starbound/assets
        - Flatpak Steam: $HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Starbound/assets

        If null, uses the default Steam location.
      '';
    };

    storageDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "$HOME/.local/share/OpenStarbound/storage";
      description = ''
        Directory for game saves and universe data.
        If null, uses XDG_DATA_HOME/OpenStarbound/storage.
      '';
    };

    logDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "$HOME/.local/share/OpenStarbound/logs";
      description = ''
        Directory for game log files.
        If null, uses XDG_DATA_HOME/OpenStarbound/logs.
      '';
    };

    modDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "$HOME/.local/share/OpenStarbound/mods";
      description = ''
        Directory for custom mods.
        If null, uses XDG_DATA_HOME/OpenStarbound/mods.
      '';
    };

    extraAssetDirs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "$HOME/OpenStarbound/custom-assets"
        "/mnt/shared/starbound-mods"
      ];
      description = ''
        Additional asset directories to load.
        Useful for workshop content or custom asset packs.
      '';
    };

    installDesktopFile = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to install the .desktop file for application menu integration.
      '';
    };

    installIcon = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to install the application icon.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ openstarboundPackage ];

  };

  meta = {
    maintainers = [ ];
    doc = ./openstarbound.md;
  };
}
