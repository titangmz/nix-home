# Waybar

Bar configuration and CSS. Colors, opacity, and blur come from `modules/theme`. Hyprland starts Waybar; there is no separate service.

The bar itself is transparent: left, center, and right modules float as three glass islands using the shared opacity and a thin border. The launcher and the focused workspace use the accent-to-blue gradient that Hyprland uses for the active window border. The bar stays minimal so it fits small screens: most controls live in the control center (`../swaync/README.md`), which the Nix button opens from the top left. Each status module has a colored icon from the theme, and every clickable control highlights on hover. A critical battery, an urgent workspace, and the privacy indicators pulse. The window title is bounded so it leaves room for the centered clock.

Each monitor shows its own workspaces and window title. Workspace tabs show an icon for each open app (`window-rewrite` in `config.jsonc`; unknown apps get a generic window icon), and the window title shows the focused app's icon. Volume is an icon; the level is in its tooltip. Microphone and screen-share indicators appear only while in use, and battery status only on machines with a battery. The network module stays hidden on a working wired connection and shows only the Wi-Fi signal icon, or a warning when there is no address or no connection; its tooltip has the address and connection speed. The tray shows only when an app puts an icon there.

Workspace tabs show only real workspaces assigned to that bar's output. Every
screen has its own workspaces 1–10 (see `../hyprland/README.md`); tabs show
that screen-local number, matching Super+1…0, through `format-icons` generated
in `default.nix`. Moved workspaces follow their new output. Hyprland's workspace
events and Waybar's output handling keep this in sync when monitors connect or
disconnect. If a screen is unplugged, its workspaces wait on a remaining screen
and can show the same number twice until it returns.
The workspace visible on each screen has a subtle filled tab; the workspace
with keyboard focus uses the accent color. Scrolling stays on the hovered
screen's existing workspaces.

| Control | Action |
| --- | --- |
| Nix button | Click to open or close the control center (also Super+N); right-click for applications |
| Workspaces | Click a number to switch; scroll to cycle this screen's existing workspaces |
| Clock | Click for the full date; hover for the calendar; scroll to browse months; right-click to toggle month/year |
| Keyboard layout | Click to cycle layouts on all keyboards |
| Volume | Click for Pavucontrol's mixer and device selection; right-click to mute; scroll for volume, capped at 100% |
| Network | Click for the network menu; middle-click for interface addresses; right-click for routes (both read-only, in Kitty) |
| VPN | Green with the VPN's name when connected, yellow while connecting, a grey shield when off. Click for the network menu |
| Power | Open the session menu: lock, suspend, log out, restart, shut down |

The network menu (`network-menu`, also installed in `~/.local/bin` for the control center) is a Rofi list of every VPN and WireGuard connection with its state, a networking on/off switch, and *Edit connections*, which opens `nm-connection-editor`. Selecting a VPN connects or disconnects it; a notification reports the result, including the error when a connection fails. `vpn-status` feeds the VPN indicator: it prints the state once, then again on every change that `nmcli monitor` reports, so the bar updates without polling. Both call `nmcli` from the session PATH so it matches the system's NetworkManager. `tests/test_network_menu.py` covers them with a fake `nmcli`.

Commands in `config.jsonc` use placeholders resolved to Nix store executables by `default.nix`. The session menu is a GTK menu from `session-menu.ui`; clicking the power button opens that menu without performing an action.

The module patches Waybar 0.15's normal and special workspace clicks to send Hyprland's Lua dispatch expressions. Named workspaces are escaped as Lua string data. Keep `move-to-monitor` disabled: this bar focuses workspaces on their owning output, rather than relocating them. The patch can be removed when the pinned Waybar supports Lua IPC upstream.

Apply with `just switch`, then restart Waybar to load the new configuration:

```bash
pkill waybar  # the process is named .waybar-wrapped, so -x would match nothing
hyprctl dispatch 'hl.dsp.exec_cmd("waybar")'
```
