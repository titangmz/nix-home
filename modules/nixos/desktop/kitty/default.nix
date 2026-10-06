{ lib, pkgs, ... }:
let
  theme = import ../../../theme { inherit lib; };
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    xdg.configFile."kitty/kitty.conf".text = theme.render (builtins.readFile ./kitty.conf);
  };
}
