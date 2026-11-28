{ lib, pkgs, ... }:
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    # Hyprland starts the history watchers (wl-paste --watch cliphist store).
    home.packages = [
      pkgs.wl-clipboard
      pkgs.cliphist
    ];
    # The scripts module puts ~/.local/bin on PATH for every profile.
    home.file.".local/bin/clipboard-history".source = ./clipboard-history;
  };
}
