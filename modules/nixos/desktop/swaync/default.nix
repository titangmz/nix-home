{ lib, pkgs, ... }:
let
  palette = import ../../../theme { inherit lib; };
  swaync = pkgs.swaynotificationcenter;
  controlCenter = pkgs.writeShellScript "control-center" (builtins.readFile ./control-center);
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    # libnotify provides notify-send. Hyprland starts swaync; it is the only
    # notification daemon, so do not enable another one.
    home.packages = [
      swaync
      pkgs.libnotify
    ];
    xdg.configFile = {
      "swaync/config.json".text = lib.replaceStrings [ "@controlCenter@" ] [ "${controlCenter}" ] (
        builtins.readFile ./config.json
      );
      "swaync/style.css".text =
        lib.replaceStrings [ "@defaultStyle@" ] [ "${swaync}/etc/xdg/swaync/style.css" ]
          (palette.render (builtins.readFile ./style.css));
    };
  };
}
