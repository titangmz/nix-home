# nix-home

Personal Home Manager configuration for servers, workstations, and one NixOS Hyprland desktop.

| Profile | For | Systems |
| --- | --- | --- |
| `server` | headless machines, Raspberry Pi included: shell, CLI tools, Git, tmux, Neovim | x86_64 and aarch64 Linux, Apple Silicon macOS |
| `pc` | Linux workstations | x86_64-linux |
| `mac` | macOS workstations | aarch64-darwin |
| `nixos` | the NixOS Hyprland desktop | x86_64-linux |

`profiles/default.nix` lists the profiles. The username, name, and email that every profile and the NixOS module use come from `profiles/user.default.nix`.

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

## Everyday controls

The maintained guides to our shortcuts and customizations:

| Guide | What's inside |
| --- | --- |
| **[tmux](modules/tmux/README.md)** | Sessions, windows, pane navigation, zoom, and appearance |
| **[Neovim](modules/neovim/README.md)** | Editing, search, splits, Git, terminals, and workstation run/test workflows |

## Using it as someone else

Leave `profiles/user.default.nix` alone. Your identity goes in `profiles/user.local.nix`, which git ignores, so pulls never conflict with it:

```nix
{
  username = "sam";
  name = "Sam Example";
  email = "sam@example.com";
}
```

`./bootstrap.sh` writes this file for you from your login name and your global Git name and email, asking for whichever is missing. Create or edit it by hand any time, then run `just switch`. Fields you leave out keep the default.

## NixOS desktop

Install NixOS so `/etc/nixos/configuration.nix` exists, clone this repository, then run:

```bash
./bootstrap.sh nixos
```

Later updates use the same `just switch`. On this profile it switches the system, then the desktop.

After the first Hyprland login, lay out monitors with `just setup-monitors`. `just setup-monitors --list` prints the output names.

The working rules are in [docs/rules.md](docs/rules.md). Each module's README sits next to that module.
