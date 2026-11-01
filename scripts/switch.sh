#!/usr/bin/env bash
# Usage: switch.sh [PROFILE] [Home Manager options]
# Applies a profile and remembers it. The nixos profile switches the system first.
set -euo pipefail

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
config_home="${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}"
PROFILE_FILE="$config_home/nix-home/profile"
# Existing files that Home Manager would replace are renamed with this suffix.
BACKUP_EXTENSION=nix-home-backup

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

# Flake URLs need percent-encoding as well as shell quoting.
encode_path() {
  local value="$1" encoded="" character code hex offset
  local LC_ALL=C
  for ((offset = 0; offset < ${#value}; offset++)); do
    character=${value:offset:1}
    case "$character" in
      [a-zA-Z0-9/._~-]) encoded+="$character" ;;
      *)
        # Mask to one byte: Bash 3.2 sign-extends bytes above 0x7F.
        printf -v code '%d' "'$character"
        printf -v hex '%%%02X' $((code & 255))
        encoded+="$hex"
        ;;
    esac
  done
  printf '%s' "$encoded"
}
FLAKE="path:$(encode_path "$REPO_DIR")"

# A profile named once is remembered; the platform alone never picks one.
PROFILE=""
if (($#)) && [[ "$1" != -* ]]; then
  PROFILE="$1"
  shift
elif [[ -f "$PROFILE_FILE" ]]; then
  PROFILE=$(<"$PROFILE_FILE")
fi
if [[ -n "$PROFILE" && ! "$PROFILE" =~ ^[a-z0-9-]+$ ]]; then
  fail 'Usage: switch.sh [PROFILE] [Home Manager options]'
fi

# A preview changes nothing: no system activation and no saved state.
preview=false
for arg in "$@"; do
  if [[ "$arg" == --dry-run ]]; then preview=true; fi
done

if [[ "$PROFILE" == nixos ]]; then
  if [[ "$(uname -s)" != Linux || (! -e /etc/NIXOS && "${NIX_HOME_TEST_NIXOS:-}" != 1) ]]; then
    fail 'The nixos profile must run on NixOS.'
  fi
  ((EUID != 0)) || fail 'Run switch.sh as the target user, not as root; it uses sudo for system activation.'
fi

command -v nix >/dev/null 2>&1 || fail 'Nix is required. Run ./bootstrap.sh PROFILE first.'

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

[[ -n "$AVAILABLE" ]] || fail "No profile supports $SYSTEM."
if [[ -z "$PROFILE" ]]; then
  fail "Usage: switch.sh [PROFILE] [Home Manager options]
No profile selected. Profiles for $SYSTEM: $AVAILABLE"
fi
if [[ " $AVAILABLE " != *" $PROFILE "* ]]; then
  fail "Profile $PROFILE is not available on $SYSTEM. Profiles for $SYSTEM: $AVAILABLE"
fi

if [[ "$PROFILE" == nixos ]]; then
  printf 'Building the NixOS configuration...\n'
  "$REPO_DIR/scripts/rebuild.sh" build
  if [[ "$preview" == false ]]; then
    printf 'Activating the NixOS configuration...\n'
    if [[ "${NIX_HOME_NO_SUDO:-}" == 1 ]]; then
      "$REPO_DIR/scripts/rebuild.sh" switch
    else
      command -v sudo >/dev/null 2>&1 || fail 'sudo is required to activate the NixOS configuration.'
      sudo "$REPO_DIR/scripts/rebuild.sh" switch
    fi
    # Use the systemd user bus directly. This ignores a stale inherited address and
    # avoids Home Manager creating a short-lived private bus whose shutdown makes
    # xfconfd emit a misleading "Name org.xfce.Xfconf lost" warning.
    export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR:-/run/user/$UID}/bus"
  fi
fi

if [[ "$preview" == false ]]; then
  mkdir -p "$config_home/nix-home"
  printf '%s\n' "$PROFILE" > "$PROFILE_FILE"
  # Hyprland links its config from this checkout.
  printf '%s\n' "$REPO_DIR" > "$config_home/nix-home/root"
fi

if [[ "$preview" == true ]]; then
  printf 'Previewing the %s Home Manager profile...\n' "$PROFILE"
else
  printf 'Activating the %s Home Manager profile...\n' "$PROFILE"
fi
exec nix run "${FLAKE}#home-manager" -- \
  switch --flake "${FLAKE}#${PROFILE}-${SYSTEM}" -b "$BACKUP_EXTENSION" "$@"
