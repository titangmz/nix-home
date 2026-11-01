# Rules

Home Manager configurations are built from profiles in `profiles/`. `profiles/default.nix` lists the profiles a machine can switch to and the systems each one supports. The other files there are layers that profiles import:

- `base.nix` holds identity and the terminal core: the shell and prompt, CLI tools, Git, tmux, Neovim, and scripts. Every profile includes it.
- `workstation.nix` is base plus the Neovim AI module, development tools, chat, v2rayN, proxychains, and zoxide. Every profile except `server` and `pi` includes it.
- `server` is base alone. `pi` is the server. `pc` is the workstation. `mac` adds Ghostty. `nixos` adds `modules/nixos/desktop`.

Exactly one layer or profile imports each module. Put a module in the lowest layer that every profile including it should have. A new profile is one file in `profiles/` and one line in `profiles/default.nix`. Give it a flake check for what it must and must not contain.

- `modules/nixos/system` owns the session: Hyprland, portals, greetd, nix-ld, flakes, PipeWire, DConf, Tumbler, Flatpak, Firefox, the Kitty package, Thunar, imv, hyprlock, hypridle, Bazaar, Warehouse, hyprbars at `/etc/hyprland-plugins/libhyprbars.so`, and Docker with its Compose plugin. The module adds user `xray` to the `docker` group. The account itself stays in `machine.nix`.
- `modules/nixos/desktop` owns GTK, Kitty config, Hyprland behavior, Waybar, Rofi, Mako, and wallpaper.
- Users, hardware, hostname, networking, and `system.stateVersion` stay in `/etc/nixos/machine.nix`. This repo does not register machines.

`modules/theme` is the only place for colors, window opacity, and blur. Shell, Waybar, Rofi, Mako, Kitty, GTK, Lazygit, and Hyprland read it.

Hyprland behavior lives in `modules/nixos/desktop/hyprland/hyprland.lua`. Activation symlinks `~/.config/hypr/hyprland.lua` to that checkout file using `~/.config/nix-home/root`, and writes `~/.config/hypr/style.lua` from the theme. Edit the Lua file, then run `just reload`. A theme change needs `just switch`, then `just reload`.

Software cursors are the shared default. Monitor names stay out of git. `just setup-monitors` orders the live outputs left to right. `just setup-monitors --list` prints each output name with its description and position. Pass names only when that order is wrong. `--force` replaces an existing layout.

Optional local files are loaded when they exist and are not managed:

- `~/.config/zsh/local.zsh`
- `~/.config/git/local`
- `~/.config/nvim` module `local`
- `~/.config/hypr/local_monitors.lua`
- `~/.config/hypr/local.lua`

Leave the tmux module unchanged unless the change is specifically about tmux.

The root holds only entry points and config: `bootstrap.sh`, the flake, the justfile, and the docs. Repo tooling goes in `scripts/`, commands installed into `~/.local/bin` go in `modules/scripts/bin/`, and tests go in `tests/`.

Every script is idempotent. `./bootstrap.sh PROFILE` is the first-run command, before `just` or even Nix exists. It installs the pinned official Nix release when Nix is missing; update `NIX_VERSION` and its published installer hash together. Later updates are `just switch` on every machine. On the nixos profile it switches the system first, so the system and the desktop never drift apart.

Switches never fail on existing files. Home Manager renames a file in its way to `<file>.nix-home-backup`; delete or merge those backups by hand.

Validate with:

```bash
nix fmt
nix flake check "path:$PWD"
```

Put module details in that module's README. This file holds the rules. `README.md` holds only what the repo is and how to bootstrap or update it.
