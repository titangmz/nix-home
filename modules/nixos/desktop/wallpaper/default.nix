{
  config,
  lib,
  pkgs,
  ...
}:
let
  startWallpaper = pkgs.writeShellScript "desktop-wallpaper" (
    lib.replaceStrings
      [ "@DEFAULT@" "@OVERRIDE_PNG@" "@OVERRIDE_JPG@" "@HYPRPAPER@" ]
      [
        (toString ./wallpaper.png)
        "${config.xdg.dataHome}/wallpapers/override.png"
        "${config.xdg.dataHome}/wallpapers/override.jpg"
        "${pkgs.hyprpaper}/bin/hyprpaper"
      ]
      (builtins.readFile ./start-wallpaper.sh)
  );
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = [ pkgs.hyprpaper ];
    xdg.dataFile."wallpapers/wallpaper.png".source = ./wallpaper.png;
    systemd.user.services.desktop-wallpaper = {
      Unit = {
        Description = "Hyprland wallpaper with a local override";
        PartOf = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = toString startWallpaper;
        RuntimeDirectory = "desktop-wallpaper";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
