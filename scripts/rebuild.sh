#!/usr/bin/env bash
set -euo pipefail

ACTION="${1-build}"
if (($#)); then shift; fi
case "$ACTION" in
  build|dry-build|dry-activate|switch|boot|test) ;;
  *) printf 'Usage: rebuild.sh [build|dry-build|dry-activate|switch|boot|test] [options]\n' >&2; exit 1 ;;
esac
if ! command -v nixos-rebuild >/dev/null 2>&1; then
  printf 'nixos-rebuild is required; run this script on NixOS.\n' >&2
  exit 1
fi

# Each machine owns its base configuration, hardware, and NixOS package pin.
exec nixos-rebuild "$ACTION" -I nixos-config=/etc/nixos/configuration.nix "$@"
