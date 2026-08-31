# NixOS module. Thin wrapper: options and package construction live in the
# shared factory so the Home Manager module stays in sync automatically.
import ../lib/mk-openstarbound-module.nix {
  path = [ "programs" ];
  mkConfig =
    { package, ... }:
    {
      environment.systemPackages = [ package ];
    };
}
