# Example NixOS configurations using the Asterbound module
#
# This file demonstrates various ways to configure Asterbound
# using the programs.asterbound module.

{ pkgs, config, ... }:

{
  # ============================================================================
  # Example 1: Basic Configuration (Recommended for most users)
  # ============================================================================

  programs.asterbound = {
    enable = true;
    # Uses default paths:
    # - Assets: $XDG_DATA_HOME/asterbound/assets
    # - Storage: $XDG_DATA_HOME/asterbound/storage
    # - Logs: $XDG_DATA_HOME/asterbound/logs
    # - Mods: $XDG_DATA_HOME/asterbound/mods
    # XDG_DATA_HOME defaults to $HOME/.local/share.
    # ASTERBOUND_RUNTIME_DIR, when set, selects the runtime data root instead.
    # Copy owned commercial assets there or set starboundAssetsPath explicitly.
  };

  # ============================================================================
  # Example 2: Flatpak Steam Configuration
  # ============================================================================

  # programs.asterbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Starbound/assets";
  # };

  # ============================================================================
  # Example 3: External Storage Configuration
  # ============================================================================

  # programs.asterbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  #   storageDir = "/mnt/games/asterbound/storage";
  #   logDir = "/mnt/games/asterbound/logs";
  #   modDir = "/mnt/games/asterbound/mods";
  # };

  # ============================================================================
  # Example 4: Multiple Asset Directories (Workshop + Custom Mods)
  # ============================================================================

  # programs.asterbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  #   extraAssetDirs = [
  #     "$HOME/asterbound/workshop-content"
  #     "$HOME/asterbound/custom-assets"
  #     "/mnt/shared/starbound-community-mods"
  #   ];
  # };

  # ============================================================================
  # Example 5: Development Setup
  # ============================================================================

  # programs.asterbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  #   storageDir = "$HOME/Development/starbound-test/saves";
  #   logDir = "$HOME/Development/starbound-test/logs";
  #   modDir = "$HOME/Development/starbound-test/mods";
  #   extraAssetDirs = [
  #     "$HOME/Development/starbound-test/test-assets"
  #   ];
  # };

  # ============================================================================
  # Example 6: Custom Package
  # ============================================================================

  # programs.asterbound = {
  #   enable = true;
  #   package = pkgs.asterbound.override {
  #     # Custom build options if needed
  #   };
  # };

  # ============================================================================
  # Example 7: Complete Gaming Setup with Steam
  # ============================================================================

  # Enable Steam for Starbound assets
  # programs.steam = {
  #   enable = true;
  #   remotePlay.openFirewall = true;
  # };

  # programs.asterbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  # };

  # Additional gaming optimizations
  # hardware.opengl = {
  #   enable = true;
  #   driSupport = true;
  #   driSupport32Bit = true;
  # };

  # ============================================================================
  # Example 8: Server Setup
  # ============================================================================

  # For a dedicated Starbound server setup
  # programs.asterbound = {
  #   enable = true;
  #   starboundAssetsPath = "/srv/starbound/assets";
  #   storageDir = "/srv/starbound/storage";
  #   logDir = "/var/log/starbound";
  #   modDir = "/srv/starbound/mods";
  # };

  # Create necessary directories
  # systemd.tmpfiles.rules = [
  #   "d /srv/starbound 0755 starbound starbound -"
  #   "d /srv/starbound/assets 0755 starbound starbound -"
  #   "d /srv/starbound/storage 0755 starbound starbound -"
  #   "d /srv/starbound/mods 0755 starbound starbound -"
  #   "d /var/log/starbound 0755 starbound starbound -"
  # ];

  # ============================================================================
  # Example 9: Multi-User Setup
  # ============================================================================

  # Enable Asterbound for all users
  # programs.asterbound.enable = true;

  # Users can override paths with environment variables:
  # export ASTERBOUND_ASSETS="/custom/path"
  # export ASTERBOUND_STORAGE="$HOME/game-saves"
  # export ASTERBOUND_LOGS="$HOME/game-logs"
  # export ASTERBOUND_MODS="$HOME/game-mods"
  # export XDG_DATA_HOME="$HOME/.local/share"
  # ASTERBOUND_RUNTIME_DIR overrides the runtime data root (assets/storage/logs/mods).

  # ============================================================================
  # Example 10: Conditional Configuration (Per-Machine)
  # ============================================================================

  # programs.asterbound = {
  #   enable = (config.networking.hostName == "gaming-pc");
  #   starboundAssetsPath =
  #     if config.networking.hostName == "gaming-pc"
  #     then "$HOME/.local/share/Steam/steamapps/common/Starbound/assets"
  #     else "/mnt/network/steam/Starbound/assets";
  # };

  # ============================================================================
  # Additional Useful Configurations
  # ============================================================================

  # Asterbound and the upstream SDK derivation need selective unfree permission.
  # Steam itself needs separate permission if enabled; commercial assets are not included.
  nixpkgs.config.allowUnfreePredicate = p:
    builtins.elem (pkgs.lib.getName p) [ "asterbound" "openstarbound-sdks" ];

  # Install useful gaming utilities
  # environment.systemPackages = with pkgs; [
  #   # Mod management tools
  #   # steamcmd
  #
  #   # Performance monitoring
  #   # mangohud
  #   # goverlay
  # ];

  # Enable gamemode for better performance
  # programs.gamemode.enable = true;

  # ============================================================================
  # Notes
  # ============================================================================

  # 1. You need to own and install Starbound (usually via Steam)
  # 2. Only leading $HOME, ${HOME}, ~/, $XDG_DATA_HOME and ${XDG_DATA_HOME}
  #    expand at runtime; other text is literal, never evaluated as shell code.
  # 3. Rebuild your system after changes: sudo nixos-rebuild switch
  # 4. Launch from app menu or run: asterbound
  # 5. Check logs if issues occur: ~/.local/share/asterbound/logs/
}
