{ pkgs, fetchFromGitHub }:

let
  rev = "27b0a472a6c9f158daf82fe147dcf7464308ed82";
  src = fetchFromGitHub {
    owner = "ErodeesFleurs";
    repo = "Asterbound";
    inherit rev;
    hash = "sha256-8/U90At4SUaOvfo6j1nOuRBYjlu2IBMoXJvSiGYACG8=";
  };
  dependencies = import "${src}/nix/dependencies.nix" { inherit pkgs; };
in
# Keep the compiler, static C++ dependencies, Lua patches and checks together.
# Replacing upstream's CMakeLists breaks this fork's C++23/runtime contract.
(pkgs.callPackage "${src}/nix/asterbound.nix" {
  inherit src dependencies;
  stdenv = dependencies.stdenv;
  sourceIdentifier = builtins.substring 0 7 rev;
  steamSupport = pkgs.stdenv.hostPlatform.isx86_64;
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
      rm "$out/bin/asterbound" "$out/bin/asterbound_server"
    '';
    meta =
      builtins.removeAttrs old.meta [ "mainProgram" ]
      // {
        homepage = "https://github.com/ErodeesFleurs/Asterbound";
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isx86_64 {
        # The GUI package now includes proprietary vendor runtimes.
        license = pkgs.lib.licenses.unfree;
      };
  })
