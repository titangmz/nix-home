{ lib, pkgs, ... }:
let
  palette = import ../palette.nix { inherit lib; };
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = with pkgs; [
      waybar
      wireplumber
      nerd-fonts.jetbrains-mono
    ];
    xdg.configFile = {
      "waybar/config.jsonc".source = ./config.jsonc;
      "waybar/style.css".text = palette.render (builtins.readFile ./style.css);
    };
    # Hyprland starts Waybar; do not enable a second systemd service.
  };
}
