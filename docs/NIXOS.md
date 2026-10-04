# NixOS setup and ownership

The NixOS desktop is an explicit `nixos-hyprland` Home Manager profile for
x86_64 NixOS. Portable Linux and macOS profiles never select it automatically.

## Automated bootstrap

After NixOS has generated `/etc/nixos/configuration.nix`, clone the repository
at a stable path and first apply the portable Home Manager profile to install
`just`:

```bash
git clone <repository-url> /home/xray/nix-home
cd /home/xray/nix-home
./switch.sh
just bootstrap-nixos
```

The bootstrap command:

1. Copies `/etc/nixos/configuration.nix` verbatim to
   `/etc/nixos/machine.nix`.
2. Replaces `configuration.nix` with a small wrapper importing `machine.nix`
   and this checkout's `modules/nixos/system` module.
3. Builds the combined configuration without activating it.
4. Activates the NixOS configuration only after the build succeeds.
5. Applies the `nixos-hyprland` Home Manager profile as the invoking user.

The command is idempotent. Later runs preserve `machine.nix` and regenerate only
the managed wrapper. It refuses to overwrite an unrecognized existing
`machine.nix`. If the build fails, neither system nor Home Manager activation
runs.

The resulting local layout is:

```text
/etc/nixos/configuration.nix          Managed import wrapper
/etc/nixos/machine.nix                Original machine configuration
/etc/nixos/hardware-configuration.nix Generated hardware configuration
```

Keep the checkout at the path recorded in the wrapper. Moving it breaks the
absolute module import until the wrapper is updated.

## Configuration ownership

Machine-specific settings remain under `/etc/nixos`, including:

- generated hardware and filesystem settings;
- bootloader configuration;
- users and groups;
- hostname and networking;
- locale and time zone;
- `system.stateVersion`;
- the machine's NixOS package source.

Reusable additions live in `modules/nixos/system`. This module owns Hyprland,
portals, audio, fonts, desktop applications, and shared system CLI packages. It
is also exported as `nixosModules.desktop`. Machines and hardware files are not
registered in this repository.

Home Manager remains standalone. `rebuild.sh` selects the local
`/etc/nixos/configuration.nix`; it does not switch Home Manager. `switch.sh`
selects the portable profile by default and the desktop only with
`--profile nixos-hyprland`.

## Manual setup

To skip the bootstrap command, add the shared module beside the generated
hardware import in `/etc/nixos/configuration.nix`:

```nix
imports = [
  ./hardware-configuration.nix
  /home/xray/nix-home/modules/nixos/system
];
```

Do not add a second `imports` attribute. Preserve all existing machine-specific
settings, build before activation, and then apply the desktop home profile:

```bash
cd /home/xray/nix-home
just build-system
just switch-system
just switch-nixos
```

When first adopting existing local Home Manager files, preserve them with:

```bash
./switch.sh --profile nixos-hyprland -b desktop-migration
```

System rebuilds use the machine's own NixOS package source. The Home Manager
flake pins remain independent.
