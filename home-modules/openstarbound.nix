# Home Manager module. Thin wrapper over the shared factory in lib/.
import ../lib/mk-openstarbound-module.nix {
  path = [ "home" "programs" ];
  mkConfig =
    { package, ... }:
    {
      home.packages = [ package ];
    };
}
