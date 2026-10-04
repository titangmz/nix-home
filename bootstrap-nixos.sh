#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
CONFIG_DIR=${NIX_HOME_BOOTSTRAP_CONFIG_DIR:-/etc/nixos}
SYSTEM_CONFIG="$CONFIG_DIR/configuration.nix"
MACHINE_CONFIG="$CONFIG_DIR/machine.nix"
MODULE="$REPO_DIR/modules/nixos/system"
MARKER="# Managed by nix-home bootstrap."

if (($#)); then
  printf 'Usage: bootstrap-nixos.sh\n' >&2
  exit 1
fi
if [[ "$(uname -s)" != "Linux" || (! -e /etc/NIXOS && "${NIX_HOME_BOOTSTRAP_TEST:-}" != "1") ]]; then
  printf 'bootstrap-nixos.sh must run on NixOS.\n' >&2
  exit 1
fi
if ((EUID == 0)); then
  printf 'Run bootstrap-nixos.sh as the target user, not as root; it uses sudo for system activation.\n' >&2
  exit 1
fi
if [[ ! -f "$SYSTEM_CONFIG" ]]; then
  printf 'Missing %s; generate the machine configuration first.\n' "$SYSTEM_CONFIG" >&2
  exit 1
fi
if [[ ! -f "$MODULE/default.nix" ]]; then
  printf 'Missing shared NixOS module: %s\n' "$MODULE/default.nix" >&2
  exit 1
fi
case "$REPO_DIR" in
  *[!a-zA-Z0-9_./+-]*)
    printf 'The checkout path contains characters that cannot be used safely as a Nix path: %s\n' "$REPO_DIR" >&2
    exit 1
    ;;
esac

SUDO=(sudo)
INSTALL_OWNER=(-o root -g root)
if [[ "${NIX_HOME_BOOTSTRAP_NO_SUDO:-}" == "1" ]]; then
  SUDO=()
  INSTALL_OWNER=()
elif ! command -v sudo >/dev/null 2>&1; then
  printf 'sudo is required to prepare and activate /etc/nixos.\n' >&2
  exit 1
fi

already_bootstrapped=false
if grep -Fq "$MARKER" "$SYSTEM_CONFIG"; then
  already_bootstrapped=true
  if [[ ! -f "$MACHINE_CONFIG" ]]; then
    printf '%s is marked as bootstrapped, but %s is missing.\n' "$SYSTEM_CONFIG" "$MACHINE_CONFIG" >&2
    exit 1
  fi
elif [[ -e "$MACHINE_CONFIG" ]]; then
  printf 'Refusing to overwrite existing %s; move it aside or reconcile it manually.\n' "$MACHINE_CONFIG" >&2
  exit 1
fi

temp_dir=$(mktemp -d)
trap 'rm -rf -- "$temp_dir"' EXIT
wrapper="$temp_dir/configuration.nix"
{
  printf '%s\n' "$MARKER"
  printf '# Machine-specific settings remain in /etc/nixos/machine.nix.\n'
  printf '{ ... }:\n'
  printf '{\n'
  printf '  imports = [\n'
  printf '    ./machine.nix\n'
  printf '    %s\n' "$MODULE"
  printf '  ];\n'
  printf '}\n'
} > "$wrapper"

if ((${#SUDO[@]})); then
  "${SUDO[@]}" -v
fi
if [[ "$already_bootstrapped" == false ]]; then
  # Copy instead of editing Nix source so every generated local setting is
  # preserved verbatim and the final wrapper can be installed atomically.
  "${SUDO[@]}" cp --preserve=mode,ownership,timestamps -- "$SYSTEM_CONFIG" "$MACHINE_CONFIG"
fi
"${SUDO[@]}" install "${INSTALL_OWNER[@]}" -m 0644 -- "$wrapper" "$SYSTEM_CONFIG"

if ((${#SUDO[@]} == 0)); then
  NIX_HOME_NIXOS_NO_SUDO=1 NIX_HOME_NIXOS_TEST="${NIX_HOME_BOOTSTRAP_TEST:-}" \
    "$REPO_DIR/switch-nixos.sh"
else
  "$REPO_DIR/switch-nixos.sh"
fi

printf 'NixOS bootstrap complete.\n'
