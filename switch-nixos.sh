#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
DRY_RUN=false

if (($#)); then
  if [[ "$1" == "--dry-run" && $# == 1 ]]; then
    DRY_RUN=true
  else
    printf 'Usage: switch-nixos.sh [--dry-run]\n' >&2
    exit 1
  fi
fi

if [[ "$(uname -s)" != "Linux" || (! -e /etc/NIXOS && "${NIX_HOME_NIXOS_TEST:-}" != "1") ]]; then
  printf 'switch-nixos.sh must run on NixOS.\n' >&2
  exit 1
fi
if ((EUID == 0)); then
  printf 'Run switch-nixos.sh as the target user, not as root; it uses sudo for system activation.\n' >&2
  exit 1
fi

printf 'Building the NixOS configuration...\n'
"$REPO_DIR/rebuild.sh" build

if [[ "$DRY_RUN" == true ]]; then
  printf 'Previewing the nixos-hyprland Home Manager profile...\n'
  exec "$REPO_DIR/switch.sh" --profile nixos-hyprland --dry-run -b nix-home-backup
fi

if [[ "${NIX_HOME_NIXOS_NO_SUDO:-}" == "1" ]]; then
  SUDO=()
elif command -v sudo >/dev/null 2>&1; then
  SUDO=(sudo)
else
  printf 'sudo is required to activate the NixOS configuration.\n' >&2
  exit 1
fi

printf 'Activating the NixOS configuration...\n'
"${SUDO[@]}" "$REPO_DIR/rebuild.sh" switch

printf 'Activating the nixos-hyprland Home Manager profile...\n'
# A private bus makes DConf/Xfconf activation independent of the caller's
# current graphical session while the system configuration still registers
# DConf for applications at runtime.
env -u DBUS_SESSION_BUS_ADDRESS "$REPO_DIR/switch.sh" --profile nixos-hyprland -b nix-home-backup
