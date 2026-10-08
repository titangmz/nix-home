# System

## Docker

`virtualisation.docker.enable` in `default.nix` starts the daemon and installs the Docker CLI. Compose is a plugin in that package, so the command is `docker compose`. The shell alias `dco` already points at it.

The socket is owned by the `docker` group. `users.users.xray.extraGroups` adds that user to the group. Log in again after switching so the session picks it up.

## Finding libraries for nix-ld

nix-ld loads a dynamically linked ELF that was not built by Nix. The interpreter `/lib64/ld-linux-x86-64.so.2` is the nix-ld stub. It searches `NIX_LD_LIBRARY_PATH`, which is `/run/current-system/sw/share/nix-ld/lib`.

`programs.nix-ld.libraries` in `default.nix` is the list of packages whose `/lib` is linked into that directory. nix-ld already contributes a base set (zlib, openssl, the compiler's libstdc++, systemd, and others). A package is added when a binary still cannot open one of its sonames.

A library built by Nix carries a `RUNPATH` to its own dependencies. List the sonames the foreign binary loads by name. The dependencies of those Nix libraries are already found.

## 1. Use the ELF, not the wrapper

```bash
BIN=/path/to/the/binary
file "$BIN"
readelf -l "$BIN" | awk '/INTERP/{getline; print}'
```

If `file` says the path is a script, open the ELF it executes and use that as `$BIN`. This guide applies when the interpreter is `/lib64/ld-linux-x86-64.so.2`.

## 2. Collect the missing sonames

```bash
readelf -d "$BIN" | awk '/NEEDED|RPATH|RUNPATH/'
ldd "$BIN" | rg 'not found'
```

`NEEDED` entries are loaded before `main`. `ldd` prints `not found` for each one nix-ld cannot open. Running the program prints the same gap as `error while loading shared libraries: <soname>`.

Leave a soname out of the list in these cases:

- `RPATH` or `RUNPATH` contains `$ORIGIN/...` and that directory next to the binary already contains the file. Those files ship with the program.
- The load path is an absolute path under `/nix/store` or `/run/opengl-driver`. Follow that file's own `RUNPATH` (step 5).

A `RPATH` entry of `/usr/lib/...` is empty on NixOS, so those `NEEDED` sonames still come from nix-ld.

## 3. Map each soname to a nixpkgs attribute

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

## 4. Try the packages in this shell

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

## 5. Leave driver stacks on `/run/opengl-driver`

`libglvnd` and `vulkan-loader` open the GPU driver through JSON files in `/run/opengl-driver/share`. Those files name an absolute store path such as `libEGL_mesa.so.0` or a Vulkan ICD. Check that file before adding `mesa` or the driver package:

```bash
readelf -d /run/opengl-driver/lib/libEGL_mesa.so.0 | rg 'NEEDED|RPATH|RUNPATH'
```

A `RUNPATH` back into that library's own store dependencies means those dependencies are already resolved. The nix-ld entry is the dispatcher the binary loads by soname (`libglvnd`, `vulkan-loader`), not the driver behind it.

## 6. Add them here

Append the confirmed attributes to `programs.nix-ld.libraries` in `default.nix`. Copy that same list into the assertion in `flake.nix`. The assertion compares the list this module returns. NixOS still concatenates it with nix-ld's built-in set.

```bash
just switch-nixos
```

After activation the new files are in `/run/current-system/sw/share/nix-ld/lib`. A new login picks up `NIX_LD_LIBRARY_PATH`. An existing session can export `NIX_LD` and `NIX_LD_LIBRARY_PATH` from step 4, with `extra` empty, once the system profile contains the libraries.
