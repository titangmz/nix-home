# Hyprland

`hyprland.lua` is the compositor behavior. Activation symlinks `~/.config/hypr/hyprland.lua` to this checkout file and writes `style.lua` from `modules/theme`.

`just reload` applies Lua edits. A theme edit needs `just switch-nixos`, then `just reload`.

Software cursors are enabled here. Optional `~/.config/hypr/local.lua` can add machine binds. `just setup-monitors` writes `~/.config/hypr/local_monitors.lua`.

hyprbars loads from `/etc/hyprland-plugins/libhyprbars.so`.
