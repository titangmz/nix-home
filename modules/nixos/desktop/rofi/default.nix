{ lib, pkgs, ... }:
let
  palette = import ../palette.nix { inherit lib; };
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = [ pkgs.rofi ];
    xdg.configFile."rofi/config.rasi".text = palette.render (builtins.readFile ./config.rasi);
  };
}
