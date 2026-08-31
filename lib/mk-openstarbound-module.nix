# Shared factory for the NixOS and Home Manager OpenStarbound modules.
# Both flavors expose identical options and build the package the same
# way; only the option namespace path and the enabled-system config differ.
#
# Returns a module function; `lib` and `pkgs` come from the module system.
{
  # Attribute path of the option namespace:
  #   [ "programs" ]          for NixOS
  #   [ "home" "programs" ]   for Home Manager
  path,
  # Builds the enabled-system config from { lib, cfg, package }.
  mkConfig,
}:

{ lib, pkgs, config, ... }:

let
  cfg = lib.getAttrFromPath (path ++ [ "openstarbound" ]) config;

  openstarboundPackage =
    if cfg.package != null then
      cfg.package
    else
      pkgs.callPackage ../pkgs/openstarbound {
        inherit (cfg)
          starboundAssetsPath
          storageDir
          logDir
          modDir
          extraAssetDirs
          ;
      };

  mkPathOption =
    example: description:
    lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      inherit example description;
    };
in
{
  options = lib.setAttrByPath path {
    openstarbound = {
      enable = lib.mkEnableOption "OpenStarbound, an open-source Starbound client with improvements";

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        example = lib.literalExpression "pkgs.openstarbound";
        description = ''
          The OpenStarbound package to use. If null, a package will be built
          with the configured paths.
        '';
      };

      starboundAssetsPath = mkPathOption "$HOME/.local/share/Steam/steamapps/common/Starbound/assets" ''
        Path to Starbound's official game assets.

        Common locations:
        - Steam: $HOME/.local/share/Steam/steamapps/common/Starbound/assets
        - Flatpak Steam: $HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Starbound/assets

        If null, uses the default Steam location.
      '';

      storageDir = mkPathOption "$HOME/.local/share/OpenStarbound/storage" ''
        Directory for game saves and universe data.
        If null, uses XDG_DATA_HOME/OpenStarbound/storage.
      '';

      logDir = mkPathOption "$HOME/.local/share/OpenStarbound/logs" ''
        Directory for game log files.
        If null, uses XDG_DATA_HOME/OpenStarbound/logs.
      '';

      modDir = mkPathOption "$HOME/.local/share/OpenStarbound/mods" ''
        Directory for custom mods.
        If null, uses XDG_DATA_HOME/OpenStarbound/mods.
      '';

      extraAssetDirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
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

      installDesktopFile = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to install the .desktop file for application menu integration.
        '';
      };

      installIcon = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to install the application icon.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    mkConfig {
      inherit lib cfg;
      package = openstarboundPackage;
    }
  );
}
