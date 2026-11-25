# Waybar

Bar configuration and CSS. Colors, opacity, and blur come from `modules/theme`. Hyprland starts Waybar; there is no separate service.

The compact floating bar uses the shared glass opacity, a thin border, and rounded controls. The launcher and active workspace use the theme accent; hover backgrounds reveal clickable controls. Window and media titles are bounded so they leave room for the centered clock and system controls.

Each monitor shows its own workspaces and window title. Media appears when a player is available; microphone and screen-share indicators appear only while in use. Battery status appears only on machines with a battery. Ethernet is labeled Wired; the address, connection speed, and Wi-Fi signal are in the network tooltip.

Workspace tabs show only real workspaces assigned to that bar's output. There
are no duplicated placeholder tabs or fixed workspace ranges per monitor. New
workspaces appear on their owning screen; moved workspaces follow their new
output. Hyprland's workspace events and Waybar's output handling keep this in
sync when monitors connect or disconnect, including when all workspaces end up
on a single screen. Workspace numbers stay the same as the keyboard shortcuts.
The workspace visible on each screen has a subtle filled tab; the workspace
with keyboard focus uses the accent color. Scrolling stays on the hovered
screen's existing workspaces.

| Control | Action |
| --- | --- |
| Nix launcher | Click for applications; right-click to run a command |
| Workspaces | Click a number to switch; scroll to cycle this screen's existing workspaces |
| Clock | Click for the full date; hover for the calendar; scroll to browse months; right-click to toggle month/year |
| Media | Click to play/pause; middle-click for previous; right-click for next (Waybar controls the displayed player) |
| CPU | Open `btop` in Kitty |
| Keyboard layout | Click to cycle layouts on all keyboards |
| Volume | Click for Pavucontrol's mixer and device selection; right-click to mute; scroll for volume, capped at 100% |
| Network | Click for interface addresses; right-click for routes; both open read-only diagnostics in Kitty |
| Keep awake | Toggle idle inhibition for presentations or videos; green means active |
| Power | Open the session menu: lock, suspend, log out, restart, shut down |

Commands in `config.jsonc` use placeholders resolved to Nix store executables by `default.nix`. The session menu is a GTK menu from `session-menu.ui`; clicking the power button opens that menu without performing an action.

The module patches Waybar 0.15's normal and special workspace clicks to send Hyprland's Lua dispatch expressions. Named workspaces are escaped as Lua string data. Keep `move-to-monitor` disabled: this bar focuses workspaces on their owning output, rather than relocating them. The patch can be removed when the pinned Waybar supports Lua IPC upstream.

Apply with `just switch`, then restart Waybar to load the new configuration:

```bash
pkill -x waybar
hyprctl dispatch 'hl.dsp.exec_cmd("waybar")'
```
