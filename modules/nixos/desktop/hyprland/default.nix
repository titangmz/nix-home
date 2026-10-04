{ lib, pkgs, ... }:
let
  palette = import ../palette.nix { inherit lib; };
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    # NixOS owns the compositor package and portals. Keep its Lua-compatible
    # version; the Home Manager pin need not provide the same config API.
    xdg.configFile."hypr/hyprland.lua".text =
      lib.replaceStrings [ "@systemctl@" ] [ "${pkgs.systemd}/bin/systemctl" ]
        (palette.render (builtins.readFile ./hyprland.lua));
  };
}
