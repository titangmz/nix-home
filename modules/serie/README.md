# Serie

[Serie](https://github.com/lusingander/serie) displays Git commit graphs in the
terminal. The workstation layer installs the nixpkgs package for pc, mac, and
nixos; the server profile does not include it.

After `just switch`, run `serie` inside a Git repository, or `serie -C <path>`
to open another repository. Press `?` for keybindings. This module uses Serie's
default configuration.

Graph rendering requires a terminal with a supported image protocol. Upstream
supports tmux only with the Kitty Unicode placeholder protocol; use
`serie -p kitty-unicode` in a compatible terminal when running inside tmux.
