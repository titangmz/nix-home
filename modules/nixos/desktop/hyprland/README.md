# Hyprland

`hyprland.lua` is the compositor behavior. Activation symlinks `~/.config/hypr/hyprland.lua` to this checkout file and writes `style.lua` from `modules/theme`.

`just reload` applies Lua edits. A theme edit needs `just switch`, then `just reload`.

English (`us`) and Persian (`ir`) are the keyboard layouts. Super+Space switches them.

Hyprshot is installed only for the NixOS profile. Print selects a region, Super+Print selects a window, and Shift+Print selects a monitor. Screenshots are saved to `~/Pictures/Screenshots` and copied to the clipboard, with a notification after capture. Hyprshot creates the directory when needed.

Software cursors are enabled here. Optional `~/.config/hypr/local.lua` can add machine binds.

`just setup-monitors` opens a Gum wizard in a terminal. Choose connected screens
from left to right, choose your main screen, then give each a unique default
workspace number. The main screen is asked first and starts at workspace 1 for
a fresh setup. The preview offers **Save and apply**, **Save for next login**,
and **Cancel**. Cancel or Ctrl-C leaves the existing file unchanged. Applying
reloads the monitor configuration, shows each screen's default workspace, and
focuses the main screen. Existing workspaces keep their numbers; moving a
default workspace to its configured screen carries its open windows with it.

The wizard writes only `~/.config/hypr/local_monitors.lua`, outside Git. Its
settings comment allows later runs to prefill your choices and remember
disconnected screens. Workspace numbers saved for disconnected screens remain
reserved to avoid conflicting defaults when those screens return. Monitor
descriptions identify screens across connector changes when unique; identical
screens without distinct descriptions fall back to connector names.

The generated file loads this checkout's `monitor-layout.lua`. That helper
handles monitor add/remove events without polling. It restores connected
screens in their saved relative order, releases bindings to disconnected
screens, and uses workspace 1 when only one screen is connected. Reconnecting
restores the saved default workspaces without overwriting the saved settings.
Unknown screens keep an existing non-conflicting workspace, or get a free
number. Hotplug preserves the user's current workspace where possible. Modes
use the highest available refresh rate at maximum resolution when configured;
unknown screens use their preferred mode. Re-run the wizard after moving the
checkout or changing available display modes.

`just setup-monitors --interactive` explicitly opens the wizard, including from
a command runner. `--list` prints output names, modes, positions, and
descriptions. For automation, explicit output names still write a layout in
left-to-right order without setting workspace defaults; `--force` replaces an
existing file. With no terminal and no names, the original writer uses the
current left-to-right order. Reload those layouts with `hyprctl reload`.

hyprbars loads from `/etc/hyprland-plugins/libhyprbars.so`. Waybar's layer is blurred so it matches the window title bars.
