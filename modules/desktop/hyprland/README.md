# Hyprland

`hyprland.lua` is the compositor behavior. Activation symlinks `~/.config/hypr/hyprland.lua` to this checkout file and writes `style.lua` from `modules/theme`.

`just reload` applies Lua edits. A theme edit needs `just switch`, then `just reload`.

English (`us`) and Persian (`ir`) are the keyboard layouts. Super+Space switches them.

Hyprshot is installed only for the NixOS profile. Print selects a region, Super+Print selects a window, and Shift+Print selects a monitor. Screenshots are saved to `~/Pictures/Screenshots` and copied to the clipboard, with a notification after capture. Hyprshot creates the directory when needed.

Super+N opens the control center (`../swaync/README.md`). Super+Shift+V opens the clipboard history (`../clipboard/README.md`); Hyprland also starts its watchers. Super+V still toggles floating.

Software cursors are enabled here. Optional `~/.config/hypr/local.lua` can add machine binds.

## Per-screen workspaces

Every screen has its own workspaces 1–10. Super+1…0 switches the focused
screen to its own workspace with that number, and Super+Shift+1…0 moves the
active window there. Focus never jumps to another screen. Super+scroll cycles
the focused screen's existing workspaces. Waybar shows the same local numbers.

`workspaces.lua` implements this. Internally, screens own blocks of
Hyprland's global workspace ids by left-to-right slot: the first screen has
1–10, the second 11–20, and so on. Each screen's first workspace is persistent
and is where it starts. After a hotplug, every workspace returns to the screen
that owns its block, carrying its windows. A workspace whose screen is
disconnected stays on a remaining screen, reachable from Waybar, until that
screen returns. If a key targets a workspace that is still on another screen,
the workspace is pulled to the focused one. `hyprland.lua` loads the helper from
the checkout path in `~/.config/nix-home/root`, so `just reload` picks up edits.

## Monitor setup

`just setup-monitors` opens a Gum wizard in a terminal. Choose connected screens
from left to right, then choose your main screen, which gets focus at startup.
Left-to-right order decides which block of workspaces each screen owns. The
preview offers **Save and apply**, **Save for next login**, and **Cancel**.
Cancel or Ctrl-C leaves the existing file unchanged. Applying reloads the
monitor configuration and focuses the main screen. Open windows are preserved.

The wizard writes only `~/.config/hypr/local_monitors.lua`, outside Git. Its
settings comment allows later runs to prefill your choices and remember
disconnected screens. Workspace numbers saved by older versions of the wizard
are ignored and dropped on the next save. Monitor descriptions identify screens
across connector changes when unique; identical screens without distinct
descriptions fall back to connector names.

The generated file loads this checkout's `monitor-layout.lua`. That helper
handles monitor add/remove events without polling. It restores connected
screens in their saved relative order and places unknown screens after them,
then hands that order to `workspaces.lua`. Without the wizard, physical
position decides the order. Hotplug preserves the user's current workspace
where possible. Modes use the highest available refresh rate at maximum
resolution when configured; unknown screens use their preferred mode. Re-run
the wizard after moving the checkout or changing available display modes.

`just setup-monitors --interactive` explicitly opens the wizard, including from
a command runner. `--list` prints output names, modes, positions, and
descriptions. For automation, explicit output names still write a layout in
left-to-right order; `--force` replaces an
existing file. With no terminal and no names, the original writer uses the
current left-to-right order. Reload those layouts with `hyprctl reload`.

hyprbars loads from `/etc/hyprland-plugins/libhyprbars.so`. Waybar's layer is blurred so it matches the window title bars.
