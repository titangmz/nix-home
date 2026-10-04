# nix-home

Personal Nix configuration for three portable Home Manager targets and one
explicit NixOS Hyprland desktop profile:

- `x86_64-linux`
- `aarch64-darwin`
- `x86_64-darwin`
- `nixos-hyprland` on x86_64 NixOS

Review `profiles/xray.nix` before setup. It contains the username, home
directory, and Git identity.

## NixOS machine

Install NixOS normally and keep its generated configuration in `/etc/nixos`.
Enable flakes, then clone this repository at a stable path:

```bash
git clone <repository-url> /home/xray/nix-home
cd /home/xray/nix-home
./switch.sh
just bootstrap-nixos
```

The initial portable switch installs `just`. `just bootstrap-nixos` is a
one-time, idempotent setup command: it preserves the generated machine settings,
builds and activates the shared NixOS configuration, and then applies the
`nixos-hyprland` Home Manager profile.

Keep the checkout at the same absolute path after bootstrapping. See
[docs/NIXOS.md](docs/NIXOS.md) for the generated `/etc/nixos` layout, safety
behavior, and manual setup.

## Home Manager-only machine

Use this path for non-NixOS Linux and macOS. Install Nix with the daemon
installer:

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Enable flakes in `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:

```ini
experimental-features = nix-command flakes
```

Open a new terminal, clone the repository, preview, and apply:

```bash
git clone <repository-url> ~/nix-home
cd ~/nix-home
./switch.sh --dry-run
./switch.sh
```

The first switch installs `just`; later updates use `just switch`. Home Manager
is run from the locked flake, so no separate Home Manager installation is
needed.

## Which command to run

Run commands from the repository checkout.

| Change | Command |
| --- | --- |
| First-time NixOS desktop setup | `just bootstrap-nixos` |
| Portable Home Manager configuration on Linux or macOS | `just switch` |
| Hyprland, Waybar, Mako, GTK, Kitty, shell, CLI, or Neovim configuration on the NixOS desktop | `just switch-nixos` |
| NixOS packages, Hyprland package, portals, audio, fonts, or other `modules/nixos/system` changes | `just build-system`, then `just switch-system` |
| Both NixOS system and desktop Home Manager changes | `just build-system`, `just switch-system`, then `just switch-nixos` |
| Local wallpaper override only | `just wallpaper` |
| Preview portable Home Manager changes | `just switch --dry-run` |
| Preview NixOS desktop Home Manager changes | `just switch-nixos --dry-run` |
| List all recipes | `just` |

On a NixOS desktop, always use `just switch-nixos` for Home Manager changes.
Running plain `just switch` selects the portable profile and removes the
Home Manager-managed desktop files and services.

`just bootstrap-nixos` is only for initial machine setup. Normal system updates
use `just build-system` and `just switch-system`.

## Validate repository changes

```bash
nix fmt
nix flake check "path:$PWD"
nix flake check "path:$PWD" --all-systems --no-build
```

Evaluation of another platform does not prove native runtime support.

## Detailed documentation

- [NixOS setup and ownership](docs/NIXOS.md)
- [Hyprland desktop](docs/DESKTOP.md)
- [Shell and CLI](docs/SHELL-AND-CLI.md)
- [WezTerm and tmux](docs/TERMINAL.md)
- [Neovim workspace](docs/NEOVIM.md)
- [Development and maintenance](docs/DEVELOPMENT.md)
- [Repository structure](STRUCTURE.md)
- [Contributor rules](AGENTS.md)
