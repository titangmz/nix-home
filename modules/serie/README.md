# Serie

[Serie](https://github.com/lusingander/serie) displays Git commit graphs in the
terminal. The workstation layer installs the nixpkgs package for pc, mac, and
nixos; the server profile does not include it.

After `just switch`, run `serie` inside a Git repository, or `serie -C <path>`
to open another repository. Press `?` for keybindings.

Graph rendering defaults to the Kitty Unicode placeholder protocol, supported
by Ghostty and Kitty both directly and inside tmux. The tmux module enables
passthrough for visible panes so the graph images reach the terminal.
For another terminal, override the protocol with `serie -p auto`; tmux rendering
still requires a terminal that supports Kitty Unicode placeholders.
