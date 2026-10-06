# nix-home

Personal configuration for portable Home Manager machines and one NixOS Hyprland desktop. The portable home is a subset of the NixOS desktop: tools installed for Home Manager-only machines are installed on NixOS as well.

Portable outputs: `x86_64-linux`, `aarch64-darwin`, `x86_64-darwin`.
NixOS home profile: `nixos-hyprland`.

`profiles/xray.nix` holds the username, home directory, and Git identity.

## Home Manager-only

Install Nix, clone this repository, then run:

```bash
./bootstrap-home.sh
```

Later updates:

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

After the first Hyprland login, lay out monitors with `just setup-monitors`.

The working rules are in [docs/rules.md](docs/rules.md). Each module's README sits next to that module.
