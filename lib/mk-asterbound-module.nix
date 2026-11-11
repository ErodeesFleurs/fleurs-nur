# Shared factory for the NixOS and Home Manager Asterbound modules.
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
  cfg = lib.getAttrFromPath (path ++ [ "asterbound" ]) config;

  asterboundPackage =
    if cfg.package != null then
      cfg.package
    else
      pkgs.callPackage ../pkgs/asterbound {
        inherit (cfg)
          starboundAssetsPath
          storageDir
          logDir
          modDir
          extraAssetDirs
          installDesktopFile
          installIcon
          ;
      };

  mkPathOption =
    example: description:
    lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      inherit example;
      description = description + ''

        Paths support literal leading $HOME, ''${HOME}, ~/,
        $XDG_DATA_HOME or ''${XDG_DATA_HOME}. All other text is literal;
        shell expressions are never evaluated.
      '';
    };
in
{
  options = lib.setAttrByPath path {
    asterbound = {
      enable = lib.mkEnableOption "Asterbound, an independent Starbound-compatible game client";

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        example = lib.literalExpression "pkgs.asterbound";
        description = ''
          The Asterbound package to use. If null, a package will be built
          with all options below. A custom package is used unchanged; configure
          its paths and desktop metadata with package.override instead.
        '';
      };

      starboundAssetsPath = mkPathOption "$HOME/.local/share/Steam/steamapps/common/Starbound/assets" ''
        Path to Starbound's official game assets.

        Common locations:
        - Steam: $HOME/.local/share/Steam/steamapps/common/Starbound/assets
        - Flatpak Steam: $HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Starbound/assets

        If null, uses $ASTERBOUND_RUNTIME_DIR/assets when set, otherwise
        $XDG_DATA_HOME/asterbound/assets; XDG_DATA_HOME defaults to $HOME/.local/share.
        ASTERBOUND_ASSETS overrides this option at runtime.
      '';

      storageDir = mkPathOption "$HOME/.local/share/asterbound/storage" ''
        Directory for game saves and universe data.
        These independent saves are not automatically imported from another game.
        If null, uses $ASTERBOUND_RUNTIME_DIR/storage when set, otherwise
        $XDG_DATA_HOME/asterbound/storage; XDG_DATA_HOME defaults to $HOME/.local/share.
        ASTERBOUND_STORAGE overrides this option at runtime.
      '';

      logDir = mkPathOption "$HOME/.local/share/asterbound/logs" ''
        Directory for game log files.
        If null, uses $ASTERBOUND_RUNTIME_DIR/logs when set, otherwise
        $XDG_DATA_HOME/asterbound/logs; XDG_DATA_HOME defaults to $HOME/.local/share.
        ASTERBOUND_LOGS overrides this option at runtime.
      '';

      modDir = mkPathOption "$HOME/.local/share/asterbound/mods" ''
        Directory for custom mods.
        If null, uses $ASTERBOUND_RUNTIME_DIR/mods when set, otherwise
        $XDG_DATA_HOME/asterbound/mods; XDG_DATA_HOME defaults to $HOME/.local/share.
        ASTERBOUND_MODS overrides this option at runtime.
      '';

      extraAssetDirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "$HOME/asterbound/custom-assets"
          "/mnt/shared/starbound-mods"
        ];
        description = ''
          Additional asset directories to load after the commercial assets
          and bundled asterbound and asterbound-compat assets, and before the mods directory.
          Paths support only literal leading $HOME, ''${HOME}, ~/,
          $XDG_DATA_HOME or ''${XDG_DATA_HOME}; other text is literal.
          No shell expressions are evaluated.
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
      package = asterboundPackage;
    }
  );
}
