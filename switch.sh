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

usage() {
  printf 'Usage: switch.sh [PROFILE] [Home Manager options]\n' >&2
}

# A profile named once is remembered; the platform alone never picks one.
config_home="${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}"
PROFILE_FILE="$config_home/nix-home/profile"
PROFILE=""
if (($#)) && [[ "$1" != -* ]]; then
  PROFILE="$1"
  shift
elif [[ -f "$PROFILE_FILE" ]]; then
  PROFILE=$(<"$PROFILE_FILE")
fi
if [[ -n "$PROFILE" && ! "$PROFILE" =~ ^[a-z0-9-]+$ ]]; then
  usage
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  printf 'Nix is required. See README.md for setup instructions.\n' >&2
  exit 1
fi

# Print the platform of the installed Nix, then the profiles that support it.
# Home configuration evaluation itself stays pure.
detected=$(NIX_HOME_PROFILES="$REPO_DIR/profiles/default.nix" nix eval --impure --raw --expr '
  let
    system = builtins.currentSystem;
    profiles = import (/. + builtins.getEnv "NIX_HOME_PROFILES");
    here = builtins.filter (name: builtins.elem system profiles.${name}) (builtins.attrNames profiles);
  in
  builtins.concatStringsSep " " ([ system ] ++ here)
')
read -r SYSTEM AVAILABLE <<<"$detected"

if [[ -z "$AVAILABLE" ]]; then
  printf 'No profile supports %s.\n' "$SYSTEM" >&2
  exit 1
fi
if [[ -z "$PROFILE" ]]; then
  usage
  printf 'No profile selected. Profiles for %s: %s\n' "$SYSTEM" "$AVAILABLE" >&2
  exit 1
fi
if [[ " $AVAILABLE " != *" $PROFILE "* ]]; then
  printf 'Profile %s is not available on %s. Profiles for %s: %s\n' "$PROFILE" "$SYSTEM" "$SYSTEM" "$AVAILABLE" >&2
  exit 1
fi

# A preview must not change which profile later switches use.
preview=false
for arg in "$@"; do
  if [[ "$arg" == --dry-run ]]; then preview=true; fi
done
if [[ "$preview" == false ]]; then
  mkdir -p "$(dirname "$PROFILE_FILE")"
  printf '%s\n' "$PROFILE" > "$PROFILE_FILE"
fi

exec nix run "${FLAKE}#home-manager" -- switch --flake "${FLAKE}#${PROFILE}-${SYSTEM}" "$@"
