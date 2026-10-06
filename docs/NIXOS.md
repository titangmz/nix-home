# NixOS setup and ownership

The NixOS desktop is an explicit `nixos-hyprland` Home Manager profile for
x86_64 NixOS. Portable Linux and macOS profiles never select it automatically.

## Automated bootstrap

After NixOS has generated `/etc/nixos/configuration.nix`, clone the repository
at a stable path and run the bootstrap script directly:

```bash
git clone <repository-url> /home/xray/nix-home
cd /home/xray/nix-home
./bootstrap-nixos.sh
```

The bootstrap command:

1. Copies `/etc/nixos/configuration.nix` verbatim to
   `/etc/nixos/machine.nix`.
2. Replaces `configuration.nix` with a small wrapper importing `machine.nix`
   and this checkout's `modules/nixos/system` module.
3. Enables `nix-command` and flakes through that shared NixOS module.
4. Builds the combined configuration without activating it.
5. Activates the NixOS configuration only after the build succeeds, making the
   Nix features available without editing `/etc/nix/nix.conf` manually.
6. Applies the flake-based `nixos-hyprland` Home Manager profile as the invoking
   user, which also installs `just` for subsequent commands.

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

Reusable additions live in `modules/nixos/system`. This module owns the
`nix-command` and flakes opt-in, Hyprland, the greetd/tuigreet login, portals,
audio, fonts, desktop applications, DConf user D-Bus activation, and shared
system CLI packages. It is also exported as
`nixosModules.desktop`. Machines and hardware files are not registered in this
repository.

At boot, greetd runs the text-based tuigreet prompt on TTY1. After successful
authentication it starts `/run/current-system/sw/bin/start-hyprland`. Tuigreet
shows the time, remembers the last username, and displays asterisks while a
password is entered. User definitions and any automatic-login policy remain in
the machine-local configuration.

Home Manager remains standalone internally. `switch-nixos.sh` coordinates the
full workflow: it uses `rebuild.sh` with the local
`/etc/nixos/configuration.nix`, activates the built system, and then uses
`switch.sh` for the desktop profile. `just switch-nixos` is its public wrapper.

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
settings, then apply the complete NixOS desktop configuration:

```bash
cd /home/xray/nix-home
just switch-nixos
```

The command preserves colliding pre-existing Home Manager files with the
`nix-home-backup` suffix, builds before system activation, and applies the home
profile only after the system switch succeeds. Use `just switch-nixos --dry-run`
to build and preview without activation.

System rebuilds use the machine's own NixOS package source. The Home Manager
flake pins remain independent.
