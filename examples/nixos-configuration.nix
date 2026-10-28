# Example NixOS configurations using the OpenStarbound module
#
# This file demonstrates various ways to configure OpenStarbound
# using the programs.openstarbound module.

{ pkgs, config, ... }:

{
  # ============================================================================
  # Example 1: Basic Configuration (Recommended for most users)
  # ============================================================================

  programs.openstarbound = {
    enable = true;
    # Uses default paths:
    # - Assets: $HOME/.local/share/Steam/steamapps/common/Starbound/assets
    # - Storage: $XDG_DATA_HOME/OpenStarbound/storage
    # - Logs: $XDG_DATA_HOME/OpenStarbound/logs
    # - Mods: $XDG_DATA_HOME/OpenStarbound/mods
    # XDG_DATA_HOME defaults to $HOME/.local/share.
  };

  # ============================================================================
  # Example 2: Flatpak Steam Configuration
  # ============================================================================

  # programs.openstarbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Starbound/assets";
  # };

  # ============================================================================
  # Example 3: External Storage Configuration
  # ============================================================================

  # programs.openstarbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  #   storageDir = "/mnt/games/OpenStarbound/storage";
  #   logDir = "/mnt/games/OpenStarbound/logs";
  #   modDir = "/mnt/games/OpenStarbound/mods";
  # };

  # ============================================================================
  # Example 4: Multiple Asset Directories (Workshop + Custom Mods)
  # ============================================================================

  # programs.openstarbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  #   extraAssetDirs = [
  #     "$HOME/OpenStarbound/workshop-content"
  #     "$HOME/OpenStarbound/custom-assets"
  #     "/mnt/shared/starbound-community-mods"
  #   ];
  # };

  # ============================================================================
  # Example 5: Development Setup
  # ============================================================================

  # programs.openstarbound = {
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

  # programs.openstarbound = {
  #   enable = true;
  #   package = pkgs.openstarbound.override {
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

  # programs.openstarbound = {
  #   enable = true;
  #   # Uses the default Steam asset path (not automatic install discovery)
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
  # programs.openstarbound = {
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

  # Enable OpenStarbound for all users
  # programs.openstarbound.enable = true;

  # Users can override paths with environment variables:
  # export OPENSTARBOUND_ASSETS="/custom/path"
  # export OPENSTARBOUND_STORAGE="$HOME/game-saves"
  # export OPENSTARBOUND_LOGS="$HOME/game-logs"
  # export OPENSTARBOUND_MODS="$HOME/game-mods"
  # export XDG_DATA_HOME="$HOME/.local/share"
  # OPENSTARBOUND_ASSETS replaces the former STARBOUND_ASSETS variable.

  # ============================================================================
  # Example 10: Conditional Configuration (Per-Machine)
  # ============================================================================

  # programs.openstarbound = {
  #   enable = (config.networking.hostName == "gaming-pc");
  #   starboundAssetsPath =
  #     if config.networking.hostName == "gaming-pc"
  #     then "$HOME/.local/share/Steam/steamapps/common/Starbound/assets"
  #     else "/mnt/network/steam/Starbound/assets";
  # };

  # ============================================================================
  # Additional Useful Configurations
  # ============================================================================

  # Steam itself requires allowing its unfree license; the engine package
  # does not supply the commercial Starbound assets.
  # nixpkgs.config.allowUnfree = true;

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
  # 4. Launch from app menu or run: openstarbound
  # 5. Check logs if issues occur: ~/.local/share/OpenStarbound/logs/
}
