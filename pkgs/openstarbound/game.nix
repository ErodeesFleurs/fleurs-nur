{ pkgs, fetchFromGitHub }:

let
  rev = "39884c92829071840e1e57a00455a91a509c219d";
  src = fetchFromGitHub {
    owner = "ErodeesFleurs";
    repo = "OpenStarbound";
    inherit rev;
    hash = "sha256-WI8C6seOMWX2BeLb+2bM3zHru13iupYUGMXx9HfBywE=";
  };
  dependencies = import "${src}/nix/dependencies.nix" { inherit pkgs; };
in
# Keep the compiler, static C++ dependencies, Lua patches and checks together.
# Replacing upstream's CMakeLists breaks this fork's C++23/runtime contract.
(pkgs.callPackage "${src}/nix/openstarbound.nix" {
  inherit src dependencies;
  stdenv = dependencies.stdenv;
  sourceIdentifier = builtins.substring 0 7 rev;
  steamSupport = pkgs.stdenv.hostPlatform.isx86_64;
  discordSupport = pkgs.stdenv.hostPlatform.isx86_64;
}).overrideAttrs
  (old: {
    # Upstream exports every executable symbol. Its static mimalloc new operators
    # then interpose on Mesa/LLVM's libstdc++ without matching scalar deletes,
    # causing an invalid free during GL driver initialization.
    env = (old.env or { }) // {
      NIX_LDFLAGS = (old.env.NIX_LDFLAGS or "") + " --exclude-libs=ALL";
    };
    # Only the final package installs game launchers. Do not leave the upstream
    # JSON-interpolating/shared-config scripts reachable through passthru.heavy.
    postInstall = (old.postInstall or "") + ''
      rm "$out/bin/starbound" "$out/bin/starbound_server"
    '';
    meta =
      builtins.removeAttrs old.meta [ "mainProgram" ]
      // {
        homepage = "https://github.com/ErodeesFleurs/OpenStarbound";
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isx86_64 {
        # The GUI package now includes proprietary vendor runtimes.
        license = pkgs.lib.licenses.unfree;
      };
  })
