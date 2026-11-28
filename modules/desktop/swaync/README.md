# Control center and notifications

SwayNC is the desktop's notification daemon and its control center. Hyprland starts `swaync`; there is no other notification daemon. `notify-send` comes from libnotify, installed here.

The control center is a glass panel under the left end of the bar. The Nix button in Waybar or Super+N opens and closes it; clicking outside or Escape closes it. It fills the screen's height, so it fits small screens. From top to bottom:

- **Toolbar**: network menu, audio mixer (Pavucontrol), clipboard history (`../clipboard/README.md`), system monitor (btop), region screenshot, and on the right the power menu (lock, suspend, log out, restart, shut down).
- **Toggles**: VPN, Network, Keep awake, and Do not disturb. A toggle shows the accent gradient when on. States are read again each time the panel opens.
  - VPN on reconnects the VPN you used most recently; with no VPN set up it opens the network menu. Off disconnects every active VPN and WireGuard connection. Pick a specific VPN from the network menu.
  - Network switches NetworkManager networking on and off.
  - Keep awake holds a logind idle inhibitor in the `keep-awake` user unit; idle daemons that honor logind inhibitors will not dim, lock, or suspend while it is on.
- **Volume** slider, with per-app volume behind the arrow.
- **Media** player, shown only while something is playing.
- **Notifications** history with *Clear*.

Popups appear at the top right under the bar. Critical notifications stay until dismissed and have a red border.

`control-center` is the script behind the buttons; `tests/test_network_menu.py` covers its VPN and networking toggles with a fake `nmcli`. `config.json` lays out the panel and `style.css` restyles SwayNC's own stylesheet, imported from the package, with colors from `modules/theme`. Hyprland blurs the panel through a layer rule in `../hyprland/hyprland.lua`.

Apply with `just switch`, then restart it: `pkill swaync; hyprctl dispatch 'hl.dsp.exec_cmd("swaync")'`. Style-only changes load with `swaync-client --reload-css`.
