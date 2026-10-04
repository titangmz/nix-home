{
  config,
  lib,
  pkgs,
  ...
}:
let
  palette = import ../palette.nix { inherit lib; };
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = with pkgs; [
      mako
      libnotify
      nerd-fonts.jetbrains-mono
    ];
    xdg.configFile."mako/config".text = lib.replaceStrings [ "@HOME@" ] [ config.home.homeDirectory ] (
      palette.render (builtins.readFile ./config)
    );
    # Hyprland starts Mako; do not enable a second notification daemon.
  };
}
