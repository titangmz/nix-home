# Ghostty

The workstation layer maintains Ghostty settings for the pc, mac, and nixos
profiles without installing Ghostty. Install it separately through your distro
or the macOS app when needed. The server profile does not write Ghostty settings.

On Linux, Home Manager writes `$XDG_CONFIG_HOME/ghostty/config` (normally
`~/.config/ghostty/config`). On macOS, it writes
`~/Library/Application Support/com.mitchellh.ghostty/config`.
Background opacity and selection colors come from `modules/theme`.

macOS also gets the theme's blur radius. The left Option key acts as Alt, so
tmux's Alt+1 to Alt+9 window keys work; the right Option key still types special
characters.

Linux uses the same 60% background opacity (40% transparency) as Kitty and
requests background blur. Both settings come from `modules/theme`. On this
repo's Hyprland desktop, Ghostty shares Kitty's compositor blur (size 5,
3 passes). On other distros, the compositor controls blur support and strength:
Ghostty cannot translate Hyprland's size and passes into a portable blur amount.
KDE Plasma supports the blur request; enable and adjust Blur in Desktop Effects.
Other desktops may need compositor rules or extensions. See the
[Ghostty blur reference](https://ghostty.org/docs/config/reference#background-blur).

The NixOS desktop continues to provide Kitty as its default terminal.

Selected text uses the theme's `selection` colour with the normal text colour on top.
