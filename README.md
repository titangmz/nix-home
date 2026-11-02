# nix-home

Personal Home Manager configuration for servers, workstations, and one NixOS Hyprland desktop.

| Profile | For | Systems |
| --- | --- | --- |
| `server` | headless machines: shell, CLI tools, Git, tmux, Neovim | Linux and macOS, x86_64 and aarch64 |
| `pi` | Raspberry Pi: the server stack | aarch64-linux |
| `pc` | Linux workstations | x86_64-linux |
| `mac` | macOS workstations | aarch64-darwin, x86_64-darwin |
| `nixos` | the NixOS Hyprland desktop | x86_64-linux |

`profiles/default.nix` lists the profiles, and `profiles/user.nix` holds the username, name, and email that every profile and the NixOS module use.

## Setup

Clone this repository and run the bootstrap with a profile. It installs Nix with the official installer when Nix is missing, then applies the profile. It is safe to run again.

```bash
./bootstrap.sh server
```

The profile is remembered. Files already in the way are renamed with a `.nix-home-backup` suffix instead of failing the switch. Later updates:

```bash
just switch
```

Any profile except `nixos` works on any supported OS, NixOS included.

## NixOS desktop

Install NixOS so `/etc/nixos/configuration.nix` exists, clone this repository, then run:

```bash
./bootstrap.sh nixos
```

Later updates use the same `just switch`. On this profile it switches the system, then the desktop.

After the first Hyprland login, lay out monitors with `just setup-monitors`. `just setup-monitors --list` prints the output names.

The working rules are in [docs/rules.md](docs/rules.md). Each module's README sits next to that module.
