#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

if (($#)); then
  printf 'Usage: bootstrap-home.sh\n' >&2
  exit 1
fi
if [[ -e /etc/NIXOS && "${NIX_HOME_BOOTSTRAP_HOME_TEST:-}" != "1" ]]; then
  printf 'This machine is NixOS. Run ./bootstrap-nixos.sh instead.\n' >&2
  exit 1
fi
if ! command -v nix >/dev/null 2>&1; then
  printf 'Nix is required. Install Nix, then run ./bootstrap-home.sh again.\n' >&2
  exit 1
fi

config_home="${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}"
nix_conf="$config_home/nix/nix.conf"
mkdir -p "$(dirname "$nix_conf")"
touch "$nix_conf"

if ! grep -Eq '^[[:space:]]*experimental-features[[:space:]]*=(.*[[:space:]])?nix-command([[:space:]]|$)' "$nix_conf" \
  || ! grep -Eq '^[[:space:]]*experimental-features[[:space:]]*=(.*[[:space:]])?flakes([[:space:]]|$)' "$nix_conf"; then
  if grep -Eq '^[[:space:]]*experimental-features[[:space:]]*=' "$nix_conf"; then
    tmp=$(mktemp)
    awk '
      !done && /^[[:space:]]*experimental-features[[:space:]]*=/ {
        line = $0
        if (line !~ /(^|[[:space:]=])nix-command([[:space:]]|$)/) line = line " nix-command"
        if (line !~ /(^|[[:space:]=])flakes([[:space:]]|$)/) line = line " flakes"
        print line
        done = 1
        next
      }
      { print }
    ' "$nix_conf" > "$tmp"
    mv "$tmp" "$nix_conf"
  else
    printf '\nexperimental-features = nix-command flakes\n' >> "$nix_conf"
  fi
fi

mkdir -p "$config_home/nix-home"
printf '%s\n' "$REPO_DIR" > "$config_home/nix-home/root"

exec "$REPO_DIR/switch.sh"
