# Configuration Examples

This directory contains example configurations for using packages from fleurs-nur.

## Contents

- [`nixos-configuration.nix`](./nixos-configuration.nix) - NixOS module configuration examples
- [`flake-example.nix`](./flake-example.nix) - Complete flake.nix example with module integration

## Quick Start

### Method 1: NixOS Module (Recommended)

The easiest way to use Asterbound is with the NixOS module:

On x86_64, allow the package and upstream Steam SDK derivation in the importing
nixpkgs configuration (Steam integration is on; Discord is off by default):

```nix
nixpkgs.config.allowUnfreePredicate = p:
  builtins.elem (pkgs.lib.getName p) [ "asterbound" "openstarbound-sdks" ];
```

ARM64 uses no proprietary SDKs.

```nix
# flake.nix
{
  inputs.fleurs-nur.url = "github:ErodeesFleurs/fleurs-nur";
  
  outputs = { nixpkgs, fleurs-nur, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        fleurs-nur.nixosModules.asterbound
        {
          programs.asterbound.enable = true;
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
    (pkgs.asterbound.override {
      starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
      storageDir = "$HOME/.local/share/asterbound/storage";
      modDir = "$HOME/.local/share/asterbound/mods";
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

  environment.systemPackages = [ pkgs.nur.repos.fleurs.asterbound ];
}
```

## Asterbound Configuration

### Using the Module

The NixOS module provides declarative configuration:

```nix
programs.asterbound = {
  enable = true;
  starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  storageDir = "/mnt/games/asterbound/storage";
  logDir = "/mnt/games/asterbound/logs";
  modDir = "/mnt/games/asterbound/mods";
  extraAssetDirs = [
    "$HOME/asterbound/workshop-content"
  ];
};
```

### Using Package Override

For package-level customization:

```nix
pkgs.asterbound.override {
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

Defaults use independent `$XDG_DATA_HOME/asterbound/{storage,logs,mods}`,
falling back to `$HOME/.local/share/asterbound`. Runtime overrides and literal
path-prefix handling are documented in the [packaging guide](../README.md#paths-and-runtime-overrides).
`ASTERBOUND_RUNTIME_DIR` overrides the default runtime data root, including assets.
Commercial assets default to `$XDG_DATA_HOME/asterbound/assets`, not the Steam install;
copy owned assets there or explicitly set `starboundAssetsPath` as shown below.
No old writable directories are reused or automatically migrated.
For an explicit independent copy, run `asterbound-import-openstarbound SOURCE [TARGET]`:
it copies assets/mods/storage, dereferences symlinks, skips sbinit/logs, and never
deletes the source. Nonempty, same, nested or cyclic destinations/sources are refused;
a failed copy can leave a partial destination.
The package owns desktop/icon files; no manual Home Manager `home.file` entries
are required.

## Common Scenarios

### Flatpak Steam

```nix
programs.asterbound = {
  enable = true;
  starboundAssetsPath = "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Starbound/assets";
};
```

### External Drive

```nix
programs.asterbound = {
  enable = true;
  storageDir = "/mnt/games/asterbound/storage";
  modDir = "/mnt/games/asterbound/mods";
};
```
