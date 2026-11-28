{ lib, pkgs, ... }:
let
  palette = import ../../theme { inherit lib; };
in
{
  # hyprlock itself is a system package (modules/nixos).
  config = lib.mkIf pkgs.stdenv.isLinux {
    xdg.configFile."hypr/hyprlock.conf".text = palette.render (builtins.readFile ./hyprlock.conf);
  };
}
