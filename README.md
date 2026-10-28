# fleurs-nur

**Fleurs's Personal [NUR](https://github.com/nix-community/NUR) Repository**

## Usage

### With Flakes

```nix
{
  inputs.fleurs-nur.url = "github:ErodeesFleurs/fleurs-nur";
  # ...
}
```

Then in your configuration:

```nix
# Add packages to system
environment.systemPackages = [
  inputs.fleurs-nur.packages.${system}.openstarbound
];

# Or use as overlay
nixpkgs.overlays = [ inputs.fleurs-nur.overlays.default ];
```

### With NUR

Add to your NixOS configuration:

```nix
{
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };
}
```

Then use packages:

```nix
environment.systemPackages = with pkgs.nur.repos.fleurs; [
  openstarbound
  uudeck
];
```

### As Overlay

```nix
{
  nixpkgs.overlays = [
    (import ((builtins.fetchTarball "https://github.com/ErodeesFleurs/fleurs-nur/archive/master.tar.gz") + "/overlay.nix"))
  ];
}
```

## Modules (NixOS & Home Manager)

This repository exports NixOS modules under `modules/` and Home Manager modules under `home-modules/`.

- NixOS module: `modules/openstarbound.nix`
- Home Manager module: `home-modules/openstarbound.nix`

Both modules expose a similar option set under `programs.openstarbound` (system) and `home.programs.openstarbound` (home).

Available options

- `enable` (bool): Enable the OpenStarbound integration.
- `package` (package | null): Use a custom package unchanged, or let the module build one with the options below. For a custom package, apply these settings with `.override`.
- `starboundAssetsPath` (string | null): Path to Starbound's official game assets.
- `storageDir`, `logDir`, `modDir` (string | null): Writable directories; null uses the defaults below.
- `extraAssetDirs` (list of string): Additional asset directories to load.
- `installDesktopFile`, `installIcon` (bool, default true): Install desktop metadata in the package. Both modules forward these options; Home Manager no longer writes duplicate `home.file` entries.

## OpenStarbound packaging

The engine is pinned to the [ErodeesFleurs/OpenStarbound fork](https://github.com/ErodeesFleurs/OpenStarbound)
at full revision `bb6eb63b7776d4aa543d69f7b151edad1be78373`.
`pkgs/openstarbound/game.nix` defines the source pin; the version is inherited
from the pinned source's `nix/openstarbound.nix`, not duplicated in the wrapper.
Packaging imports that source's `nix/dependencies.nix` and `nix/openstarbound.nix`
with the caller's nixpkgs rather than maintaining a second dependency/build recipe.
The wrapper's `passthru.heavy` exposes raw binaries, tools and assets. Game launchers
are installed only by the final package; the upstream shared-config scripts are
not installed in the heavy output.

This is not a freely licensed replacement for the commercial game: the pinned
source does not grant a top-level license. Consult its installed
`share/doc/openstarbound/OPENSOURCE.md`
and applicable component licenses. Starbound's proprietary assets are **not**
distributed by this package; you must own Starbound and provide its assets.
The default asset location is
`$HOME/.local/share/Steam/steamapps/common/Starbound/assets`.

### Paths and runtime overrides

Writable defaults remain `$XDG_DATA_HOME/OpenStarbound/{storage,logs,mods}`,
with `XDG_DATA_HOME` falling back to `$HOME/.local/share`. The capitalized
`OpenStarbound` directory is preserved so existing saves are not silently moved.
`OPENSTARBOUND_RUNTIME_DIR` changes the base directory for these defaults.

Runtime environment variables override package/module settings:

| Path | Priority (highest first) |
| --- | --- |
| Commercial assets | `OPENSTARBOUND_ASSETS`, `starboundAssetsPath`, Steam default |
| Storage | `OPENSTARBOUND_STORAGE`, `storageDir`, default |
| Logs | `OPENSTARBOUND_LOGS`, `logDir`, default |
| Mods | `OPENSTARBOUND_MODS`, `modDir`, default |

When migrating an existing shell setup, replace `STARBOUND_ASSETS` with
`OPENSTARBOUND_ASSETS`; the old environment variable is no longer read.

Path strings support literal leading `$HOME`, `${HOME}`, `~/`, `$XDG_DATA_HOME`,
or `${XDG_DATA_HOME}`. All other text is literal: there is no general shell
expansion, command substitution, or `eval`. In Nix indented strings, escape a
literal interpolation prefix as `''${HOME}`; in double-quoted Nix strings use
`"\${HOME}/..."`. Paths need not be shell-quoted inside a Nix string.

Boot configuration is serialized with `jq`, preserving quotes, backslashes and
other JSON-sensitive characters without evaluating path contents. Asset scan order
is commercial assets, bundled `opensb`, `extraAssetDirs` in order, then mods;
the engine also applies asset metadata priorities and dependencies.
`openstarbound`, `starbound` and `starbound_server` use the wrapper;
`--print-bootconfig` prints its generated configuration. An explicit
`-bootconfig` is passed through instead of replacing the supplied configuration.
Generated configurations use private per-invocation temporary directories, are
retained while the engine runs, and are removed on normal exit or handled signals.
Relative configured paths are resolved against the launch directory.
These are packaging hardening changes, not a claim that all engine vulnerabilities
have been audited or fixed.

Static archive symbols are kept private with `--exclude-libs=ALL`. This prevents
the engine's mimalloc C++ allocation operators from interposing on Mesa/LLVM's
libstdc++ and causing mismatched frees during graphics initialization.

Customize packages with `.override` (there is no `.withPaths` API):

```nix
pkgs.openstarbound.override {
  starboundAssetsPath = "$HOME/Games/Starbound/assets";
  storageDir = "$XDG_DATA_HOME/OpenStarbound/storage";
  installDesktopFile = false;
  installIcon = false;
}
```

See [configuration examples](examples/README.md). The weekly tracking workflow
compares the pin against the fork's default branch and opens an issue; it does not
automatically update or deploy the package.

The imported build definitions require import-from-derivation (IFD), enabled by
this repository's CI. Both x86_64-linux and aarch64-linux are supported; the caller
must supply a recent compatible nixpkgs. Steam/Discord SDK integration is not
enabled by default.

Run packaging security regressions with:

```sh
nix build .#openstarbound.tests.launcher .#openstarbound.tests.driver-initialization --no-link
```

The driver regression exercises real Mesa/LLVM initialization without commercial
assets or a running display.
