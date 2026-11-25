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
characters. On Linux, blur is controlled by the compositor.

The NixOS desktop continues to provide Kitty as its default terminal.

Selected text uses the theme's `selection` colour with the normal text colour on top.
