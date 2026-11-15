# Tmux

Ctrl-a prefix, `tmux-256color` panes, and the Nix-managed Catppuccin plugin.

Windows number from 1 and renumber when one closes, so they always run 1 to n. Alt+1 to Alt+9 jump straight to that window without the prefix; numbers past the last window are ignored. On macOS this needs Ghostty's left Option key acting as Alt, which `modules/ghostty` sets. Kitty sends Alt as is.

Copy-mode and mouse selections use the theme's `selection` colour instead of Catppuccin's surface0 grey.
