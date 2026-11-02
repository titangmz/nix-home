# Scripts

Each non-hidden executable file in `bin/` next to this README is installed into `~/.local/bin` on every profile. The directory itself is not owned, so machine-local commands can sit beside these.

- `tm [NAME]` attaches to a tmux session, creating it in the current directory if needed. `NAME` defaults to the directory's name. Inside tmux it switches sessions instead of nesting.
- `serve [DIR] [PORT]` shares a directory over HTTP with a file listing, using Caddy. It defaults to the current directory and port 8000, and listens on every interface so other machines on the network can reach it. Ctrl-C stops it.
