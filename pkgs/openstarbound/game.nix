{ pkgs, fetchFromGitHub }:

let
  rev = "bb6eb63b7776d4aa543d69f7b151edad1be78373";
  src = fetchFromGitHub {
    owner = "ErodeesFleurs";
    repo = "OpenStarbound";
    inherit rev;
    hash = "sha256-oUCvmk7edAYrX2dXrWvnqZcjp7k6IbzCb3G0C9oXoLc=";
  };
  dependencies = import "${src}/nix/dependencies.nix" { inherit pkgs; };
in
# Keep the compiler, static C++ dependencies, Lua patches and checks together.
# Replacing upstream's CMakeLists breaks this fork's C++23/runtime contract.
(pkgs.callPackage "${src}/nix/openstarbound.nix" {
  inherit src dependencies;
  stdenv = dependencies.stdenv;
  sourceIdentifier = builtins.substring 0 7 rev;
}).overrideAttrs (old: {
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
  meta = builtins.removeAttrs old.meta [ "mainProgram" ] // {
    homepage = "https://github.com/ErodeesFleurs/OpenStarbound";
  };
})
