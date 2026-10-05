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

Install NixOS normally and keep its generated configuration in `/etc/nixos`,
then clone this repository at a stable path:

```bash
git clone <repository-url> /home/xray/nix-home
cd /home/xray/nix-home
./bootstrap-nixos.sh
```

The bootstrap is a one-time, idempotent setup command: it preserves the
generated machine settings, enables `nix-command` and flakes through the NixOS
configuration, builds and activates that configuration, and then applies the
`nixos-hyprland` Home Manager profile. That Home Manager activation installs
`just` for later use; no manual `/etc/nix/nix.conf` edit is needed.

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
| First-time NixOS desktop setup | `./bootstrap-nixos.sh` |
| Portable Home Manager configuration on Linux or macOS | `just switch` |
| Any system or home configuration on the NixOS desktop | `just switch-nixos` |
| Create a local monitor layout | `just setup-monitors LEFT [RIGHT ...]` |
| Local wallpaper override only | `just wallpaper` |
| Exit the current Hyprland session | `just logout` |
| Preview portable Home Manager changes | `just switch --dry-run` |
| Preview NixOS desktop Home Manager changes | `just switch-nixos --dry-run` |
| List all recipes | `just` |

On a NixOS desktop, always use `just switch-nixos`. It builds before activation,
switches the system, and then applies the complete desktop Home Manager profile.
That profile includes the managed Rofi `drun` theme used by Super-D and Waybar.
Running plain `just switch` selects the portable profile and removes the desktop
files and services.

`./bootstrap-nixos.sh` (or `just bootstrap-nixos` when `just` is already
available) is only for initial machine setup. All later NixOS updates use one
`just switch-nixos` command.

To create the machine-local monitor layout, first get the output names (such as
`eDP-1`, `DP-1`, or `HDMI-A-1`) from Hyprland:

```bash
hyprctl monitors all
```

Then pass those names in physical left-to-right order. For example, with an
external DisplayPort monitor to the left of the laptop display:

```bash
just setup-monitors DP-1 eDP-1
hyprctl reload
```

Run this inside the Hyprland session. The setup command creates
`~/.config/hypr/local_monitors.lua` once and refuses to overwrite it.

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
