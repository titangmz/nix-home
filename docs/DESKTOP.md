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
`modules/nixos/desktop/mako`. NixOS owns the Lua-compatible compositor package,
portals, and compositor-matched plugins such as hyprbars; it also registers DConf
on the user D-Bus so Home Manager can apply GTK preferences before linking the
desktop files. Home Manager owns Waybar, Rofi, and Mako. Hyprland Lua loads
hyprbars from `/etc/hyprland-plugins/libhyprbars.so` and styles window title
bars from the shared palette at Kitty's 60% opacity so compositor blur shows
through. Hyprland startup commands manage Waybar and Mako
lifecycle without duplicate Home Manager services.

Shared colors live in `modules/nixos/desktop/palette.nix`. Lua, CSS, Rofi, and
Mako sources use placeholders rendered from that palette. Focused windows use
an opaque mauve/blue gradient with subdued inactive borders. Rofi automatically
loads its managed `~/.config/rofi/config.rasi` for the Super-D application
launcher.

The desktop installs `imv` as the Wayland-native image viewer and registers it
for common image formats. Launch it with `imv FILE` or open an image from
Thunar. The NixOS system module enables Tumbler so Thunar can generate image
thumbnails; `imv` handles opening the full image rather than thumbnail creation.

The desktop uses the Nix-managed Bibata Modern Classic cursor at 24 pixels.
Home Manager applies the XCursor theme to GTK and XWayland, while Hyprland uses
the same XCursor fallback instead of Hyprcursor. Hardware cursors are disabled
because their NVIDIA cursor plane flickers on the dual-monitor setup; Hyprland
composites the pointer with the desktop instead.

After applying live style changes, reload the relevant process:

```bash
hyprctl reload config-only
makoctl reload
```

Restart Waybar when its configuration or CSS changes.

## Machine-local monitors

The shared Hyprland configuration uses a portable fallback monitor rule and
optionally loads `~/.config/hypr/local_monitors.lua`. To create that local file,
first find the connector names:

```bash
hyprctl monitors all
```

Then pass them in physical left-to-right order:

```bash
just setup-monitors DP-1 eDP-1
hyprctl reload
```

The setup command queries the active outputs and refuses to overwrite an
existing file. Its generated rules put the first output at `0x0`, place later
outputs with `auto-right`, use automatic scaling, and select the highest refresh
rate offered at each monitor's maximum resolution. This avoids Hyprland's raw
`highrr` behavior choosing a low-resolution mode solely for a slightly higher
refresh rate. Edit the local file directly if a different resolution, refresh
rate, scale, vertical offset, or order is needed. Home Manager switches leave
it untouched.

Exit the current Hyprland session with:

```bash
just logout
```

## GTK and Thunar

The desktop module manages Catppuccin Mocha GTK with mauve accents,
Papirus-Dark folder icons, and Noto Sans. Thunar uses icon view, the shortcuts
sidebar, breadcrumbs, folders-first sorting, and Tumbler-generated image
thumbnails. Close and reopen Thunar after applying theme changes.

Xfconf D-Bus activation is provided for the Hyprland user session. Theme
packages remain Nix-managed. `switch-nixos.sh` applies Home Manager settings
over the canonical systemd user bus rather than creating a temporary D-Bus
session, so Xfconf remains attached to the running user session.

## Wallpaper

The bundled image is `modules/nixos/desktop/wallpaper/wallpaper.png`. Hyprland
starts the `desktop-wallpaper` user service at login.

After applying Home Manager once, set a wallpaper from any directory with:

```bash
set-wallpaper path/to/image.jpg
```

The command accepts `.png` and `.jpg`, copies the image into the local override
directory, removes any override in the other format, and restarts the wallpaper
service. The source image can be a relative or absolute path.

To manage the override manually instead, put a PNG or JPEG (or a symlink) at
one of:

```text
~/.local/share/wallpapers/override.png
~/.local/share/wallpapers/override.jpg
```

When both files exist, `override.png` takes precedence.

Then run:

```bash
just wallpaper
```

Remove the override and restart the service to restore the bundled image. The
override is selected at service startup, so it does not require a Nix rebuild.
The bundled image is also installed at
`~/.local/share/wallpapers/wallpaper.png`.
