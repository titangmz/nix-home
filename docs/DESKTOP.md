# Hyprland desktop

`profiles/nixos-hyprland.nix` extends the portable Home Manager configuration
with `modules/nixos/desktop`. Apply desktop changes with:

```bash
just switch-nixos
```

This single command handles both the NixOS system and desktop Home Manager
configuration. Do not substitute `just switch` on this machine: that command is
the portable, non-NixOS workflow and excludes desktop files and services.

## Components

Hyprland's Lua configuration lives in `modules/nixos/desktop/hyprland`, Waybar
configuration and CSS in `modules/nixos/desktop/waybar`, the application launcher
theme in `modules/nixos/desktop/rofi`, and Mako styling in
`modules/nixos/desktop/mako`. NixOS owns the Lua-compatible compositor package
and portals; it also registers DConf on the user D-Bus so Home Manager can apply
GTK preferences before linking the desktop files. Home Manager owns Waybar,
Rofi, and Mako. Hyprland startup commands manage Waybar and Mako lifecycle without
duplicate Home Manager services.

Shared colors live in `modules/nixos/desktop/palette.nix`. Lua, CSS, Rofi, and
Mako sources use placeholders rendered from that palette. Focused windows use
an opaque mauve/blue gradient with subdued inactive borders. Rofi automatically
loads its managed `~/.config/rofi/config.rasi` for the Super-D application
launcher.

After applying live style changes, reload the relevant process:

```bash
hyprctl reload config-only
makoctl reload
```

Restart Waybar when its configuration or CSS changes.

Exit the current Hyprland session with:

```bash
just logout
```

## GTK and Thunar

The desktop module manages Catppuccin Mocha GTK with mauve accents,
Papirus-Dark folder icons, and Noto Sans. Thunar uses icon view, the shortcuts
sidebar, breadcrumbs, and folders-first sorting. Close and reopen Thunar after
applying theme changes.

Xfconf D-Bus activation is provided for the Hyprland user session. Theme
packages remain Nix-managed.

## Wallpaper

The bundled image is `modules/nixos/desktop/wallpaper/wallpaper.png`. Hyprland
starts the `desktop-wallpaper` user service at login.

For a machine-local replacement, put a PNG or symlink at:

```text
~/.local/share/wallpapers/override.png
```

Then run:

```bash
just wallpaper
```

Remove the override and restart the service to restore the bundled image. The
override is selected at service startup, so it does not require a Nix rebuild.
The bundled image is also installed at
`~/.local/share/wallpapers/wallpaper.png`.
