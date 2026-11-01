# nix-home

Personal Home Manager configuration for servers, workstations, and one NixOS Hyprland desktop.

| Profile | For | Systems |
| --- | --- | --- |
| `server` | headless machines: shell, CLI tools, Git, tmux, Neovim | Linux and macOS, x86_64 and aarch64 |
| `pc` | Linux workstations | x86_64-linux |
| `mac` | macOS workstations | aarch64-darwin, x86_64-darwin |
| `nixos` | the NixOS Hyprland desktop | x86_64-linux |

`profiles/default.nix` lists the profiles, and `profiles/base.nix` holds the username, home directory, and Git identity.

## Home Manager-only

Install Nix, clone this repository, then run it with a profile:

```bash
./bootstrap-home.sh server
```

The profile is remembered. Later updates:

```bash
just switch
```

## NixOS

Install NixOS so `/etc/nixos/configuration.nix` exists, clone this repository, then run:

```bash
./bootstrap-nixos.sh
```

Later updates:

```bash
just switch-nixos
```

After the first Hyprland login, lay out monitors with `just setup-monitors`. `just setup-monitors --list` prints the output names.

The working rules are in [docs/rules.md](docs/rules.md). Each module's README sits next to that module.
