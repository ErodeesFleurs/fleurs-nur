# You can use this file as a nixpkgs overlay. This is useful in the
# case where you don't want to add the whole NUR namespace to your
# configuration.

final: prev:

let
  inherit (prev) lib;
  nurPkgs = import ./default.nix { pkgs = prev; };
in
# Only derivations may leak into the top-level nixpkgs namespace; module
# sets and other helper attributes stay reachable through the flake.
lib.filterAttrs (_: v: lib.isDerivation v) nurPkgs
