# Working rules

Read [docs/rules.md](docs/rules.md) before changing configuration. Module details belong in the README next to that module.

Keep portable Home Manager a subset of the NixOS desktop. Keep colors, opacity, and blur in `modules/theme`.

Validate with `nix fmt` and `nix flake check "path:$PWD"`.

## Commands

```bash
nix fmt                          # format (nixfmt-tree)
nix flake check "path:$PWD"      # all checks for the current system
just switch                      # apply portable Home Manager for this machine
just switch-nixos                # NixOS: nixos-rebuild switch, then the nixos-hyprland home
just switch-nixos --dry-run      # build system, preview the desktop home
just reload                      # Hyprland: reload after editing hyprland.lua
```

Always use the `path:` flake URL. It includes uncommitted and untracked files, which a plain git flake would ignore.

Run a single flake check:

```bash
nix build "path:$PWD#checks.aarch64-darwin.home"     # or .switch, .neovim
nix build "path:$PWD#checks.x86_64-linux.nixos-module" # Linux-only: also .nixos-hyprland
```

The shell-script tests are plain Python `unittest` files. Without env vars they target the scripts in this checkout, so they run directly:

```bash
python3 tests/test_switch.py
python3 tests/test_switch.py SwitchTests.<test_name>
python3 -m unittest discover -s tests/scripts -p 'test_*.py'
```

## Architecture

**Two layers, one subset rule.** `home.nix` is the portable Home Manager layer used on every machine. `profiles/nixos-hyprland.nix` imports `home.nix` plus `modules/nixos/desktop`. Anything installed on a portable machine must also be on the NixOS desktop, and each package belongs to exactly one layer.

**Flake outputs** (`flake.nix`):
- `homeConfigurations.<system>` for `x86_64-linux`, `aarch64-darwin`, `x86_64-darwin`, built from `home.nix`. `switch.sh` picks one from `builtins.currentSystem`.
- `homeConfigurations.nixos-hyprland`, selected only with `switch.sh --profile nixos-hyprland`. Platform detection never enables the desktop.
- `nixosModules.desktop` is `modules/nixos/system`. This repo does not define `nixosConfigurations`. `bootstrap-nixos.sh` moves the generated config to `/etc/nixos/machine.nix` and writes a wrapper `configuration.nix` that imports it plus the module by absolute checkout path. `rebuild.sh` runs `nixos-rebuild` against `/etc/nixos/configuration.nix`, so the system uses the machine's own nixpkgs pin, not the flake lock.
- `codexPackage` is passed via `extraSpecialArgs` from a separate `nixpkgs-codex` input. Only Codex uses that input.

**NixOS split.** `modules/nixos/system` is a NixOS module (session, services, system packages, Docker). `modules/nixos/desktop` is a Home Manager module (GTK, Kitty config, Hyprland, Waybar, Rofi, Mako, wallpaper). Users, hardware, hostname, networking, and `stateVersion` live only in `/etc/nixos/machine.nix`.

**Theme.** `modules/theme/default.nix` is a plain function `{ lib }: { ... }`, not a module. Consumers `import ../theme { inherit lib; }` and read colors, opacity, blur, or helpers like `render` and `styleLua`. All colors, window opacity, and blur go there and nowhere else.

**Hyprland is not in the store.** Activation symlinks `~/.config/hypr/hyprland.lua` to the checkout's `modules/nixos/desktop/hyprland/hyprland.lua`, using the path that `switch-nixos.sh` writes to `~/.config/nix-home/root`. Lua edits need only `just reload`. `~/.config/hypr/style.lua` is generated from the theme, so theme changes need `just switch-nixos` then `just reload`.

**Checks are assertions.** The `checks` in `flake.nix` assert concrete facts about the evaluated configs. Examples: the portable home must not write desktop config files, Kitty opacity, nix-ld libraries, Docker group membership, and strings inside `hyprland.lua`. When you move or rename something these reference, update the assertion too. The `neovim` check runs `tests/neovim.lua` headless and asserts no duplicate keymaps.
