# Rules

These are the rules for changing this repository. What each module does is in the README next to it; the commands and architecture map are in [AGENTS.md](../AGENTS.md).

## Profiles and layers

Home Manager configurations are built from profiles in `profiles/`. `profiles/default.nix` lists the profiles a machine can switch to and the systems each one supports. The other files there are layers that profiles import:

- `base.nix` holds identity and the terminal core: the shell and prompt, zoxide, CLI tools, Git, tmux, Neovim, and scripts. Every profile includes it.
- `workstation.nix` is base plus everything a personal machine has beyond the server core. Every profile except `server` includes it.
- `server` is base alone; switch.sh picks its x86_64 or aarch64 build from the machine, so a Raspberry Pi uses it too. `pc` and `mac` are workstations. `nixos` adds `modules/desktop`.

Exactly one layer or profile imports each module. Put a module in the lowest layer that every profile including it should have. A new profile is one file in `profiles/` and one line in `profiles/default.nix`. Include it in flake evaluation and build checks.

The server being a subset of every workstation is the default, not an absolute requirement. A server-only module or other intentional profile-specific difference is allowed when the requested behavior calls for it. Put it in the appropriate profile and document the reason in the module's README. Shared functionality still belongs in the common layers.

## Ownership

- Identity is read only through `profiles/user.nix`. The tracked values live in `profiles/user.default.nix`. Another person's values go in the gitignored `profiles/user.local.nix`, never in the default file.
- `modules/theme` is the only place for colors, window opacity, and blur.
- `modules/nixos` is the NixOS system module: the session, services, and system packages ([README](../modules/nixos/README.md)). It may add the user from `profiles/user.nix` to groups, but the account itself stays in `machine.nix`.
- `modules/desktop` is the Home Manager half of the NixOS desktop ([README](../modules/desktop/README.md)).
- Users, hardware, hostname, networking, and `system.stateVersion` stay in `/etc/nixos/machine.nix`. This repo does not register machines.
- Monitor names stay out of git. The monitor wizard writes them to `~/.config/hypr/local_monitors.lua` ([Hyprland README](../modules/desktop/hyprland/README.md)).

The root holds only entry points and config: `bootstrap.sh`, the flake, the justfile, and the docs. Repo tooling goes in `scripts/`, commands installed into `~/.local/bin` go in `modules/scripts/bin/`, and tests go in `tests/`.

Optional local files are loaded when they exist and are not managed:

- `~/.config/zsh/local.zsh`
- `~/.config/git/local`
- `~/.config/nvim` module `local`
- `~/.config/hypr/local_monitors.lua`
- `~/.config/hypr/local.lua`

## Scripts and switching

Every script is idempotent. `./bootstrap.sh PROFILE` is the first-run command, before `just` or even Nix exists. It installs the pinned official Nix release when Nix is missing; update `NIX_VERSION` and its published installer hash together. Later updates are `just switch` on every machine. On the nixos profile it switches the system first, so the system and the desktop never drift apart.

Switches never fail on existing files. Home Manager renames a file in its way to `<file>.nix-home-backup`; delete or merge those backups by hand.

## Documentation

Put module details in that module's README, and keep inventories (what a module installs or enables) there only. This file holds the rules. `README.md` holds only what the repo is and how to bootstrap or update it.

Leave the tmux module unchanged unless the change is specifically about tmux.
Whenever tmux controls change, update `modules/tmux/README.md` in the same change. Keep it as the reference for our tmux controls.
Whenever Neovim customizations or hotkeys change, update `modules/neovim/README.md` in the same change. Keep it as the reference for our editor's behavior and controls; put development implementation details in `modules/neovim/development/README.md`.

## Tests and validation

Validate with `nix fmt` and `just check`. `just check` evaluates every system's checks, so Linux, Pi, and NixOS desktop assertions run even on the Mac. It then builds this machine's checks.

Test behavior, integration failures, and meaningful regressions. Do not maintain package presence/absence inventories or assertions that merely repeat literal settings, colors, or source strings. Routine package additions are covered by evaluation and build checks. Add focused tests when there is actual behavior or an interaction to verify.
