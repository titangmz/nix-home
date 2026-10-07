# Rules

Portable Home Manager is the shared layer. The NixOS desktop profile imports it, then adds the desktop. A package belongs in one layer.

- Portable modules own CLI tools, Git, the shell, tmux, Neovim, scripts, and the theme.
- `modules/nixos/system` owns the session: Hyprland, portals, greetd, nix-ld, flakes, PipeWire, DConf, Tumbler, Flatpak, Firefox, the Kitty package, Thunar, imv, hyprlock, hypridle, Bazaar, Warehouse, and hyprbars at `/etc/hyprland-plugins/libhyprbars.so`.
- `modules/nixos/desktop` owns GTK, Kitty config, Hyprland behavior, Waybar, Rofi, Mako, and wallpaper.
- Users, hardware, hostname, networking, and `system.stateVersion` stay in `/etc/nixos/machine.nix`. This repo does not register machines.

`modules/theme` is the only place for colors, window opacity, and blur. Shell, Waybar, Rofi, Mako, Kitty, GTK, Lazygit, and Hyprland read it.

Hyprland behavior lives in `modules/nixos/desktop/hyprland/hyprland.lua`. Activation symlinks `~/.config/hypr/hyprland.lua` to that checkout file using `~/.config/nix-home/root`, and writes `~/.config/hypr/style.lua` from the theme. Edit the Lua file, then run `just reload`. A theme change needs `just switch-nixos`, then `just reload`.

Software cursors are the shared default. Monitor names stay out of git. `just setup-monitors` orders the live outputs left to right. `just setup-monitors --list` prints each output name with its description and position. Pass names only when that order is wrong. `--force` replaces an existing layout.

Optional local files are loaded when they exist and are not managed:

- `~/.config/zsh/local.zsh`
- `~/.config/git/local`
- `~/.config/nvim` module `local`
- `~/.config/hypr/local_monitors.lua`
- `~/.config/hypr/local.lua`

Leave the tmux module unchanged unless the change is specifically about tmux.

Every script is idempotent. `./bootstrap-home.sh` and `./bootstrap-nixos.sh` are the first-run commands, before `just` exists. Later updates are `just switch` or `just switch-nixos`.

Validate with:

```bash
nix fmt
nix flake check "path:$PWD"
```

Put module details in that module's README. This file holds the rules. `README.md` holds only what the repo is and how to bootstrap or update it.
