{ lib, pkgs, ... }:
let
  theme = import ../theme { inherit lib; };
in
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.file."Library/Application Support/com.mitchellh.ghostty/config".text = ''
      background-opacity = ${theme.ghostty.opacity}
      background-blur = ${toString theme.ghostty.blurRadius}
    '';
  };
}
