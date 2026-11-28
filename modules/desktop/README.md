# Desktop

The Home Manager half of the NixOS Hyprland desktop, imported only by `profiles/nixos.nix`. The system half (session, services, system packages) is [`modules/nixos`](../nixos/README.md).

Each part has its own directory and README: [Hyprland](hyprland/README.md), [hyprlock](hyprlock/README.md), [Waybar](waybar/README.md), [SwayNC](swaync/README.md), [clipboard history](clipboard/README.md), [Rofi](rofi/README.md), [Kitty](kitty/README.md), and [wallpaper](wallpaper/README.md). `default.nix` itself sets the cursor, the GTK theme and icons, imv as the image viewer, the user folders, and Thunar's settings through Xfconf.

## User folders

This module writes `~/.config/user-dirs.dirs` naming only the folders in use, Downloads and Pictures. Apps read it to choose where downloads and saves go. Flatpak apps depend on it: Chrome's Flatpak is granted `xdg-download`, and without this file that permission resolves to nothing, so the sandbox cannot see `~/Downloads` and saves fall back to document-portal paths under `/run/user/1000/doc/`.
