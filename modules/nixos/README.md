# NixOS system

The NixOS module, exported as `nixosModules.desktop`. The machine's `/etc/nixos/configuration.nix` imports it by absolute checkout path. The Home Manager half of the desktop is [`modules/desktop`](../desktop/README.md). Users, hardware, hostname, networking, and `system.stateVersion` stay in `/etc/nixos/machine.nix`.

It enables flakes, nix-ld, Hyprland, greetd with tuigreet, portals, audio, DConf, Tumbler, Flatpak, Docker, OpenSSH, and the system session packages: Firefox, Kitty, Thunar, imv, hyprlock, hypridle, nm-applet, Bazaar, and Warehouse. Bazaar and Warehouse are the native Flatpak store and manager. hyprbars is installed at `/etc/hyprland-plugins/libhyprbars.so`.

`./bootstrap.sh nixos` preserves the generated configuration as `/etc/nixos/machine.nix`, installs the wrapper `configuration.nix` that imports it and this module, and applies the system and desktop. Later updates use `just switch`, which switches the system before the desktop. Both can be run again. Run `./bootstrap.sh nixos` again after moving the checkout or this module, so the wrapper points at the new path.

## SSH

`services.openssh.enable` starts the OpenSSH server. Host-specific networking,
firewall rules, users, and authorized keys remain in `/etc/nixos/machine.nix`.

## Docker

`virtualisation.docker.enable` in `default.nix` starts the daemon and installs the Docker CLI. Compose is a plugin in that package, so the command is `docker compose`. The shell alias `dco` already points at it.

The socket is owned by the `docker` group. The module adds the user named in `profiles/user.nix` to that group. Log in again after switching so the session picks it up.

## Fonts

Desktop fonts go in `fonts.packages` in `default.nix`, never in Home Manager `home.packages` or `gtk.font.package`. NixOS builds the fontconfig cache with the system, so it always describes the files that are installed.

Fonts in `~/.nix-profile/share/fonts` are cached in `~/.cache/fontconfig` instead. fontconfig keeps a cache until the directory's mtime changes, and every store path has the same mtime, so an update to a font package leaves the cache describing the old files. GTK then fails to load the faces it lists and draws every character as a box.

If that happens anyway, rebuild the cache and restart the app:

```bash
fc-cache -rf
pkill -f bazaar   # the process is named .bazaar-wrapped
```

## Finding libraries for nix-ld

The current list (glib, alsa-lib, Wayland, libdrm, libgbm, libglvnd, libX11, and the Vulkan loader) is there for the Zed Flatpak, which leaves its sandbox and runs its bundled editor on the host. The steps below find the libraries for any other binary.

nix-ld loads a dynamically linked ELF that was not built by Nix. The interpreter `/lib64/ld-linux-x86-64.so.2` is the nix-ld stub. It searches `NIX_LD_LIBRARY_PATH`, which is `/run/current-system/sw/share/nix-ld/lib`.

`programs.nix-ld.libraries` in `default.nix` is the list of packages whose `/lib` is linked into that directory. nix-ld already contributes a base set (zlib, openssl, the compiler's libstdc++, systemd, and others). A package is added when a binary still cannot open one of its sonames.

A library built by Nix carries a `RUNPATH` to its own dependencies. List the sonames the foreign binary loads by name. The dependencies of those Nix libraries are already found.

### 1. Use the ELF, not the wrapper

```bash
BIN=/path/to/the/binary
file "$BIN"
readelf -l "$BIN" | awk '/INTERP/{getline; print}'
```

If `file` says the path is a script, open the ELF it executes and use that as `$BIN`. This guide applies when the interpreter is `/lib64/ld-linux-x86-64.so.2`.

### 2. Collect the missing sonames

```bash
readelf -d "$BIN" | awk '/NEEDED|RPATH|RUNPATH/'
ldd "$BIN" | rg 'not found'
```

`NEEDED` entries are loaded before `main`. `ldd` prints `not found` for each one nix-ld cannot open. Running the program prints the same gap as `error while loading shared libraries: <soname>`.

Leave a soname out of the list in these cases:

- `RPATH` or `RUNPATH` contains `$ORIGIN/...` and that directory next to the binary already contains the file. Those files ship with the program.
- The load path is an absolute path under `/nix/store` or `/run/opengl-driver`. Follow that file's own `RUNPATH` (step 5).

A `RPATH` entry of `/usr/lib/...` is empty on NixOS, so those `NEEDED` sonames still come from nix-ld.

### 3. Map each soname to a nixpkgs attribute

`nix-locate` prints the attribute that installs a file. Build the index once:

```bash
nix shell nixpkgs#nix-index -c nix-index
nix shell nixpkgs#nix-index -c nix-locate --top-level libfoo.so.1
```

The attribute is the name before the output dot (`glib` from `glib.out`). One attribute often owns several missing sonames. `glib` provides `libgio-2.0.so.0`, `libglib-2.0.so.0`, and `libgobject-2.0.so.0`. Confirm a guess by building it:

```bash
find "$(nix-build --no-out-link '<nixpkgs>' -A glib)/lib" -name 'libgio-2.0.so*'
```

The name committed in this repo has to exist in the flake's nixpkgs. Top-level names are the ones used in `default.nix` (`libx11`, which is also `xorg.libX11`).

### 4. Try the packages in this shell

```bash
mapfile -t outs < <(nix-build --no-out-link -E 'with import <nixpkgs> {}; [
  glib
]')
extra=$(IFS=:; echo "${outs[*]/%//lib}")
export NIX_LD=/run/current-system/sw/share/nix-ld/lib/ld.so
export NIX_LD_LIBRARY_PATH="/run/current-system/sw/share/nix-ld/lib:$extra"

ldd "$BIN" | rg 'not found' || echo 'startup libs resolved'
"$BIN"
```

Add the next missing attribute to the `nix-build` list and export the path again. Stop when `ldd` prints no `not found` lines and the program gets past startup.

`ldd` only sees `NEEDED`. A later `dlopen` fails at the moment the program uses that feature, with the soname in the error. `strings` lists every soname compiled into the binary, including ones this run never opens:

```bash
strings "$BIN" | rg -o 'lib[A-Za-z0-9_+.-]+\.so(\.[0-9]+)?' | sort -u
```

Treat that output as candidates. While the program is still running, see which libraries the process mapped:

```bash
awk '{print $NF}' "/proc/$PID/maps" | rg '\.so' | xargs -n1 basename | sort -u
```

`$PID` is the process started above. Keep an attribute when its soname appears there, or when the program fails without it.

### 5. Leave driver stacks on `/run/opengl-driver`

`libglvnd` and `vulkan-loader` open the GPU driver through JSON files in `/run/opengl-driver/share`. Those files name an absolute store path such as `libEGL_mesa.so.0` or a Vulkan ICD. Check that file before adding `mesa` or the driver package:

```bash
readelf -d /run/opengl-driver/lib/libEGL_mesa.so.0 | rg 'NEEDED|RPATH|RUNPATH'
```

A `RUNPATH` back into that library's own store dependencies means those dependencies are already resolved. The nix-ld entry is the dispatcher the binary loads by soname (`libglvnd`, `vulkan-loader`), not the driver behind it.

### 6. Add them here

Append the confirmed attributes to `programs.nix-ld.libraries` in `default.nix`. NixOS concatenates that list with nix-ld's built-in set.

```bash
just switch
```

After activation the new files are in `/run/current-system/sw/share/nix-ld/lib`. A new login picks up `NIX_LD_LIBRARY_PATH`. An existing session can export `NIX_LD` and `NIX_LD_LIBRARY_PATH` from step 4, with `extra` empty, once the system profile contains the libraries.

## OpenVPN

OpenVPN runs through NetworkManager, which `machine.nix` enables; this module adds its OpenVPN plugin. Hyprland starts `nm-applet` without a tray icon; it only asks for VPN passwords and saves them. The VPN indicator and network menu in Waybar are the controls (see [`modules/desktop/waybar`](../desktop/waybar/README.md)).

- Import: choose *Edit connections* in the network menu (or *Advanced Network Configuration* in Rofi), press **+**, choose *Import a saved VPN configuration*, and pick the `.ovpn` file. Certificates and keys referenced by the file are copied in.
- Connect: click the VPN indicator in Waybar and select the connection. From a terminal: `nmcli connection up <name>`.
- Passwords go into GNOME Keyring, which greetd unlocks with the login password.

DNS servers set with `networking.nameservers` in `machine.nix` are used ahead of the VPN's. Remove them if VPN-internal names fail to resolve.

After the first switch that adds the plugin, restart NetworkManager (`sudo systemctl reload dbus && sudo systemctl restart NetworkManager`) or reboot. Until then a connection fails with "org.freedesktop.NetworkManager.openvpn not installed".
