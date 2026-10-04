#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

# Flake URLs need percent-encoding as well as shell quoting.
encode_path() {
  local value="$1" encoded="" character hex offset
  local LC_ALL=C
  for ((offset = 0; offset < ${#value}; offset++)); do
    character=${value:offset:1}
    case "$character" in
      [a-zA-Z0-9/._~-]) encoded+="$character" ;;
      *)
        printf -v hex '%%%02X' "'$character"
        encoded+="$hex"
        ;;
    esac
  done
  printf '%s' "$encoded"
}
FLAKE="path:$(encode_path "$REPO_DIR")"

# Opt in explicitly; platform detection alone must not enable a desktop.
PROFILE=""
HM_ARGS=()
while (($#)); do
  case "$1" in
    --profile)
      if (($# < 2)) || [[ "$2" != "nixos-hyprland" ]]; then
        printf 'Usage: switch.sh [--profile nixos-hyprland] [Home Manager options]\n' >&2
        exit 1
      fi
      PROFILE="$2"
      shift 2
      ;;
    *) HM_ARGS+=("$1"); shift ;;
  esac
done

if ! command -v nix >/dev/null 2>&1; then
  printf 'Nix is required. See README.md for setup instructions.\n' >&2
  exit 1
fi

# Read the platform of the installed Nix; home configuration evaluation stays pure.
SYSTEM=$(nix eval --impure --raw --expr builtins.currentSystem)
case "$SYSTEM" in
  x86_64-linux|aarch64-darwin|x86_64-darwin) ;;
  *)
    printf 'Unsupported system: %s. Supported: x86_64-linux, aarch64-darwin, x86_64-darwin.\n' "$SYSTEM" >&2
    exit 1
    ;;
esac

if [[ -n "$PROFILE" && "$SYSTEM" != "x86_64-linux" ]]; then
  printf 'Profile %s requires x86_64-linux; detected %s.\n' "$PROFILE" "$SYSTEM" >&2
  exit 1
fi

exec nix run "${FLAKE}#home-manager" -- switch --flake "${FLAKE}#${PROFILE:-$SYSTEM}" "${HM_ARGS[@]}"
