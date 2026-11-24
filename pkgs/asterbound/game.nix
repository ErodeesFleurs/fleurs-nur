{ pkgs, fetchFromGitHub }:

let
  rev = "efe1057f1b6cd48a91216d4ef88429db972169a2";
  src = fetchFromGitHub {
    owner = "ErodeesFleurs";
    repo = "Asterbound";
    inherit rev;
    hash = "sha256-8yB3PNdKv0R+GTiZOC9/CnMYaweolS7BzB4ujogI5sU=";
  };
  dependencies = import "${src}/nix/dependencies.nix" { inherit pkgs; };
in
assert pkgs.lib.assertMsg (
  pkgs.lib.versionAtLeast dependencies.libcpr.version "1.14.2"
) "Asterbound requires CPR 1.14.2 or newer.";
# Keep the compiler, static C++ dependencies, Lua patches and checks together.
# Replacing upstream's whole CMakeLists breaks its C++23/runtime contract.
(pkgs.callPackage "${src}/nix/asterbound.nix" {
  inherit src dependencies;
  stdenv = dependencies.stdenv;
  sourceIdentifier = builtins.substring 0 7 rev;
  steamSupport = pkgs.stdenv.hostPlatform.isx86_64;
}).overrideAttrs
  (old: {
    # CPR's SamePatchVersion policy rejects newer releases. Preserve the
    # minimum above, but request the actual matching headers/library version.
    postPatch = (old.postPatch or "") + ''
      substituteInPlace source/CMakeLists.txt \
        --replace-fail 'find_package(cpr 1.14.2 CONFIG REQUIRED)' \
        'find_package(cpr ${dependencies.libcpr.version} CONFIG REQUIRED)'
    '';
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
