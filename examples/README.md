# Configuration Examples

This directory contains example configurations for using packages from fleurs-nur.

## Contents

- [`nixos-configuration.nix`](./nixos-configuration.nix) - NixOS module configuration examples
- [`flake-example.nix`](./flake-example.nix) - Complete flake.nix example with module integration

## Quick Start

### Method 1: NixOS Module (Recommended)

The easiest way to use OpenStarbound is with the NixOS module:

```nix
# flake.nix
{
  inputs.fleurs-nur.url = "github:ErodeesFleurs/fleurs-nur";
  
  outputs = { nixpkgs, fleurs-nur, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        fleurs-nur.nixosModules.openstarbound
        {
          programs.openstarbound.enable = true;
        }
      ];
    };
  };
}
```

### Method 2: Direct Package Installation

For more control over the package:

```nix
# configuration.nix
{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (import ((builtins.fetchTarball "https://github.com/ErodeesFleurs/fleurs-nur/archive/master.tar.gz") + "/overlay.nix"))
  ];

  environment.systemPackages = [
    (pkgs.openstarbound.override {
      starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
      storageDir = "$HOME/.local/share/OpenStarbound/storage";
      modDir = "$HOME/.local/share/OpenStarbound/mods";
    })
  ];
}
```

### Method 3: Traditional NUR

```nix
{ pkgs, ... }:
{
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  environment.systemPackages = [ pkgs.nur.repos.fleurs.openstarbound ];
}
```

## OpenStarbound Configuration

### Using the Module

The NixOS module provides declarative configuration:

```nix
programs.openstarbound = {
  enable = true;
  starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  storageDir = "/mnt/games/OpenStarbound/storage";
  logDir = "/mnt/games/OpenStarbound/logs";
  modDir = "/mnt/games/OpenStarbound/mods";
  extraAssetDirs = [
    "$HOME/OpenStarbound/workshop-content"
  ];
};
```

### Using Package Override

For package-level customization:

```nix
pkgs.openstarbound.override {
  starboundAssetsPath = "/path/to/assets";
  storageDir = "/path/to/storage";
  logDir = "/path/to/logs";
  modDir = "/path/to/mods";
  extraAssetDirs = [ "/extra/assets" ];
}
```

Use `.override`; there is no `withPaths` convenience function.
With either module, a non-null `package` is used unchanged, so apply path and
desktop metadata options to that package with `.override`.

Defaults preserve `$XDG_DATA_HOME/OpenStarbound/{storage,logs,mods}` (capital O/S),
falling back to `$HOME/.local/share/OpenStarbound`. Runtime overrides and literal
path-prefix handling are documented in the [packaging guide](../README.md#paths-and-runtime-overrides).
The package owns desktop/icon files; no manual Home Manager `home.file` entries
are required.

## Common Scenarios

### Flatpak Steam

```nix
programs.openstarbound = {
  enable = true;
  starboundAssetsPath = "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Starbound/assets";
};
```

### External Drive

```nix
programs.openstarbound = {
  enable = true;
  storageDir = "/mnt/games/OpenStarbound/storage";
  modDir = "/mnt/games/OpenStarbound/mods";
};
```
