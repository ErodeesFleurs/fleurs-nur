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
  inputs.fleurs-nur.packages.${system}.asterbound
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
  asterbound
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

- NixOS module: `modules/asterbound.nix`, exported as `nixosModules.asterbound` by the flake.
- Home Manager module: `home-modules/asterbound.nix`, exported as `homeModules.asterbound`.

Both modules expose a similar option set under `programs.asterbound` (system) and `home.programs.asterbound` (home).

Available options

- `enable` (bool): Enable the Asterbound integration.
- `package` (package | null): Use a custom package unchanged, or let the module build one with the options below. For a custom package, apply these settings with `.override`.
- `starboundAssetsPath` (string | null): Path to Starbound's official game assets; null uses the independent runtime's `assets` directory.
- `storageDir`, `logDir`, `modDir` (string | null): Writable directories; null uses the defaults below.
- `extraAssetDirs` (list of string): Additional asset directories to load.
- `installDesktopFile`, `installIcon` (bool, default true): Install desktop metadata in the package. Both modules forward these options; Home Manager no longer writes duplicate `home.file` entries.

## Asterbound packaging

The engine is pinned to [ErodeesFleurs/Asterbound](https://github.com/ErodeesFleurs/Asterbound)
at full revision `92d59a8b321f6b0127505160afae096b203e9c1e`,
with source hash `sha256-W15hzw6gCvRAPN7hRmacJgCg/JO03Hgdn+SaLmqysKk=`.
`pkgs/asterbound/game.nix` defines the source pin. The pinned source's
`version.json` records the independent product version `0.1.0.0`, bundled asset
version `0.1.15.1`, and base Starbound version `1.4.4`; these are not interchangeable.
The package version is read by upstream `nix/asterbound.nix`, not duplicated in
the wrapper. Packaging imports that source's `nix/dependencies.nix` and
`nix/asterbound.nix` with the caller's nixpkgs rather than maintaining a second
dependency/build recipe.
The wrapper's `passthru.heavy` exposes raw binaries, tools and assets. Game launchers
are installed only by the final package; the upstream shared-config scripts are
not installed in the heavy output.

This is not a freely licensed replacement for the commercial game: the pinned
source does not grant a top-level license. Consult its installed
`share/doc/asterbound/OPENSOURCE.md`
and applicable component licenses. Starbound's proprietary assets are **not**
distributed by this package; you must own Starbound and provide its assets.
Place them in the independent runtime's `assets` directory, import them explicitly
as described below, or configure an existing installation's assets path, for example
`$HOME/.local/share/Steam/steamapps/common/Starbound/assets`. The Steam path is
an explicit option, not an automatic fallback.

On x86_64, Steam integration is enabled and Discord integration is off by default.
The caller's unfree allowlist must include `[ "asterbound" "openstarbound-sdks" ]`;
the upstream SDK derivation intentionally retains the name `openstarbound-sdks`.
A global `allowUnfree = true` is not required. SDK versions follow the engine
source pin: editing another local engine checkout does not update the published
package. Enabling Discord in the upstream build requires your own positive decimal
int64 application ID (at most `9223372036854775807`); no legacy Discord application
identity is supplied.
Standalone client launchers default `SteamAppId` to Starbound's `211820` and
preserve a nonempty inherited value; server launchers do not set it. Steam requires
the desktop client and ownership of Starbound; explicitly enabled Discord integration
requires its desktop client. Build integration alone does not prove authentication.

### Paths and runtime overrides

Writable defaults are `$XDG_DATA_HOME/asterbound/{assets,storage,logs,mods}`,
with `XDG_DATA_HOME` falling back to `$HOME/.local/share`.
`ASTERBOUND_RUNTIME_DIR` changes the base directory for these defaults.
This is an independent runtime: the launcher neither migrates old data nor
automatically shares OpenStarbound's writable directories.

Runtime environment variables override package/module settings:

| Path | Priority (highest first) |
| --- | --- |
| Commercial assets | `ASTERBOUND_ASSETS`, `starboundAssetsPath`, runtime `assets` default |
| Storage | `ASTERBOUND_STORAGE`, `storageDir`, runtime `storage` default |
| Logs | `ASTERBOUND_LOGS`, `logDir`, runtime `logs` default |
| Mods | `ASTERBOUND_MODS`, `modDir`, runtime `mods` default |

There are no old package, module, command, or environment-variable aliases.
Migrate configuration references to `asterbound`, `programs.asterbound`,
`home.programs.asterbound`, and the `ASTERBOUND_*` variables; `OPENSTARBOUND_*`
and `STARBOUND_ASSETS` are not read. `starboundAssetsPath` keeps its name because
it identifies the proprietary Starbound assets.

Path strings support literal leading `$HOME`, `${HOME}`, `~/`, `$XDG_DATA_HOME`,
or `${XDG_DATA_HOME}`. All other text is literal: there is no general shell
expansion, command substitution, or `eval`. In Nix indented strings, escape a
literal interpolation prefix as `''${HOME}`; in double-quoted Nix strings use
`"\${HOME}/..."`. Paths need not be shell-quoted inside a Nix string.

Boot configuration is serialized with `jq`, preserving quotes, backslashes and
other JSON-sensitive characters without evaluating path contents. Asset scan order
is commercial assets, bundled `asterbound` and `asterbound-compat`, `extraAssetDirs`
in order, then mods; the engine also applies asset metadata priorities and
dependencies. The physical upstream directories `assets/asterbound` and
`assets/asterbound-compat` are installed under `share/asterbound/assets`.
Virtual `opensb` paths and metadata identities such as `opensb_base` and
`opensb_compat` remain compatibility contracts, not stale product branding.
The commands `asterbound` and `asterbound_server` use the wrapper;
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
pkgs.asterbound.override {
  starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  storageDir = "$XDG_DATA_HOME/asterbound/storage";
  installDesktopFile = false;
  installIcon = false;
}
```

### Explicitly importing an OpenStarbound runtime

Stop **both games and all their servers** before importing. The installed upstream
helper is `asterbound-import-openstarbound SOURCE [TARGET]`; `SOURCE` must be the
old runtime root containing `assets`, `mods`, and/or `storage`, not its `storage`
subdirectory. For example:

```sh
asterbound-import-openstarbound "$HOME/.local/share/OpenStarbound"
```

With no `TARGET`, the helper uses `ASTERBOUND_RUNTIME_DIR`, otherwise
`$XDG_DATA_HOME/asterbound` (falling back to `$HOME/.local/share/asterbound`).
An explicit target must also be selected for later launches with
`ASTERBOUND_RUNTIME_DIR` or equivalent path settings.
Run the import before the first Asterbound launch: the target must be absent or
completely empty, and the helper refuses to overwrite existing contents.
It rejects identical or nested source/target paths, a symlink target, source
directory-link cycles, and source links pointing into the target.

Only `assets`, `mods`, and `storage` are copied, including user configuration
inside `storage`. Source symlinks are dereferenced into independent files and
directories, including linked commercial assets; this can require substantial
disk space but does not share writable saves or modify/delete the source.
`sbinit.config`, `logs`, and log files/rotations are excluded.
If copying fails, a partial destination may remain and is **not** automatically
deleted. Inspect it and preserve anything needed before choosing a fresh empty
target or deliberately removing that partial copy; rerunning does not merge it.

If the old runtime has no commercial assets, provide them in the new `assets`
directory or configure `starboundAssetsPath`/`ASTERBOUND_ASSETS` explicitly before
launching. Importing data and preserving virtual asset identities do not promise
compatibility with every OpenStarbound version, mod, save, or multiplayer server.

See [configuration examples](examples/README.md). The weekly tracking workflow
compares the pin against Asterbound's default branch and opens an issue; it does not
automatically update or deploy the package.

The imported build definitions require import-from-derivation (IFD), enabled by
this repository's CI. Evaluation uses
`nix-instantiate --eval --strict --json --read-write-mode` to force every package's
`drvPath` and `meta`, excluding module sets, while retaining restricted evaluation.
Write access to the Nix store is required to register IFD source derivations in a
cold store; a read-only `nix-env -qa` query can fail with `.drv is not valid`.
Both x86_64-linux and aarch64-linux are supported; the caller must supply a recent
compatible nixpkgs. ARM64 builds remain SDK-free because the vendored Linux SDKs
only provide x86_64 binaries.

Run packaging security regressions with:

```sh
NIXPKGS_ALLOW_UNFREE=1 nix build --impure \
  .#asterbound.tests.launcher .#asterbound.tests.driver-initialization --no-link
```

The driver regression exercises real Mesa/LLVM initialization without commercial
assets or a running display.
