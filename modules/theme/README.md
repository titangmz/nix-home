# Theme

Catppuccin colors, GTK flavor and accent, window opacity, and blur settings live here. Other modules read this file instead of copying those values. Ghostty on Linux shares Kitty's opacity and requests compositor blur; its Linux blur toggle and separate macOS opacity and blur radius live here too.

Hyprland receives them as `~/.config/hypr/style.lua` on each desktop activation.

`selection` is the one colour for selected text: Ghostty, Kitty, tmux copy mode, and Neovim's Visual mode, picker rows, and file tree cursor row. It is lavender mixed into the base, so it shows on the clear background while the text on it stays readable.
