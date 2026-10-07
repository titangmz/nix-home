# Hyprland

`hyprland.lua` is the compositor behavior. Activation symlinks `~/.config/hypr/hyprland.lua` to this checkout file and writes `style.lua` from `modules/theme`.

`just reload` applies Lua edits. A theme edit needs `just switch-nixos`, then `just reload`.

English (`us`) and Persian (`ir`) are the keyboard layouts. Super+Space switches them.

Software cursors are enabled here. Optional `~/.config/hypr/local.lua` can add machine binds. `just setup-monitors --list` prints output names. `just setup-monitors` writes `~/.config/hypr/local_monitors.lua`.

hyprbars loads from `/etc/hyprland-plugins/libhyprbars.so`. Waybar's layer is blurred so it matches the window title bars.
