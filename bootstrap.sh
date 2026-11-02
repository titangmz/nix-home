#!/usr/bin/env bash
# First run on any machine: ./bootstrap.sh PROFILE
# Installs Nix if it is missing, then applies the profile. Every step can run again.
set -euo pipefail

REPO_DIR=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
config_home="${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}"

# The official installer, pinned so every machine runs the same script.
# Update both together; the hash is published next to the installer.
NIX_VERSION=2.35.2
NIX_INSTALLER_SHA256=9adda97297d9e8ab360df95c729eabff4f4f93d6db091953c3a68f29e3fb130c
NIX_PROFILE_SCRIPT=${NIX_HOME_BOOTSTRAP_NIX_PROFILE:-/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

is_nixos() {
  [[ "$(uname -s)" == Linux && (-e /etc/NIXOS || "${NIX_HOME_TEST_NIXOS:-}" == 1) ]]
}

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  else
    shasum -a 256 "$1" | cut -d ' ' -f 1
  fi
}

install_nix() {
  command -v curl >/dev/null 2>&1 || fail 'curl is required to install Nix.'
  installer=$(mktemp "${TMPDIR:-/tmp}/nix-installer.XXXXXX")
  trap 'rm -f -- "$installer"' EXIT
  printf 'Installing Nix %s...\n' "$NIX_VERSION"
  curl -fsSL "https://releases.nixos.org/nix/nix-$NIX_VERSION/install" -o "$installer"
  if [[ "$(sha256 "$installer")" != "$NIX_INSTALLER_SHA256" ]]; then
    fail "The Nix $NIX_VERSION installer does not match its pinned checksum."
  fi
  # Flakes replace channels, so no nixpkgs channel is added.
  sh "$installer" --daemon --yes --no-channel-add
  # The bootstrap ends in exec, which skips the EXIT trap.
  rm -f -- "$installer"
}

ensure_nix() {
  command -v nix >/dev/null 2>&1 && return
  # Nix may be installed already, but not loaded into this shell yet.
  if [[ ! -e "$NIX_PROFILE_SCRIPT" ]]; then
    install_nix
  fi
  set +u
  # shellcheck source=/dev/null
  . "$NIX_PROFILE_SCRIPT"
  set -u
  command -v nix >/dev/null 2>&1 || fail 'Nix is installed but not on PATH. Open a new shell and run ./bootstrap.sh again.'
}

enable_flakes() {
  local nix_conf="$config_home/nix/nix.conf"
  mkdir -p "$(dirname "$nix_conf")"
  touch "$nix_conf"
  if grep -Eq '^[[:space:]]*experimental-features[[:space:]]*=(.*[[:space:]])?nix-command([[:space:]]|$)' "$nix_conf" \
    && grep -Eq '^[[:space:]]*experimental-features[[:space:]]*=(.*[[:space:]])?flakes([[:space:]]|$)' "$nix_conf"; then
    return
  fi
  if grep -Eq '^[[:space:]]*experimental-features[[:space:]]*=' "$nix_conf"; then
    local tmp
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
}

# The nixos profile also needs /etc/nixos to import the system module.
wire_nixos() {
  local config_dir=${NIX_HOME_BOOTSTRAP_CONFIG_DIR:-/etc/nixos}
  local system_config="$config_dir/configuration.nix"
  local machine_config="$config_dir/machine.nix"
  local module="$REPO_DIR/modules/nixos/system"
  local marker="# Managed by nix-home bootstrap."

  [[ -f "$system_config" ]] || fail "Missing $system_config; generate the machine configuration first."
  [[ -f "$module/default.nix" ]] || fail "Missing shared NixOS module: $module/default.nix"
  case "$REPO_DIR" in
    *[!a-zA-Z0-9_./+-]*)
      fail "The checkout path contains characters that cannot be used safely as a Nix path: $REPO_DIR"
      ;;
  esac

  local sudo=(sudo) install_owner=(-o root -g root)
  if [[ "${NIX_HOME_NO_SUDO:-}" == 1 ]]; then
    sudo=()
    install_owner=()
  elif ! command -v sudo >/dev/null 2>&1; then
    fail 'sudo is required to prepare and activate /etc/nixos.'
  fi

  local already_bootstrapped=false
  if grep -Fq "$marker" "$system_config"; then
    already_bootstrapped=true
    [[ -f "$machine_config" ]] || fail "$system_config is marked as bootstrapped, but $machine_config is missing."
  elif [[ -e "$machine_config" ]]; then
    fail "Refusing to overwrite existing $machine_config; move it aside or reconcile it manually."
  fi

  temp_dir=$(mktemp -d)
  trap 'rm -rf -- "$temp_dir"' EXIT
  local wrapper="$temp_dir/configuration.nix"
  {
    printf '%s\n' "$marker"
    printf '# Machine-specific settings remain in /etc/nixos/machine.nix.\n'
    printf '{ ... }:\n'
    printf '{\n'
    printf '  imports = [\n'
    printf '    ./machine.nix\n'
    printf '    %s\n' "$module"
    printf '  ];\n'
    printf '}\n'
  } > "$wrapper"

  if ((${#sudo[@]})); then
    "${sudo[@]}" -v
  fi
  if [[ "$already_bootstrapped" == false ]]; then
    # Copy instead of editing Nix source so every generated local setting is
    # preserved verbatim and the final wrapper can be installed atomically.
    "${sudo[@]}" cp --preserve=mode,ownership,timestamps -- "$system_config" "$machine_config"
  fi
  "${sudo[@]}" install "${install_owner[@]}" -m 0644 -- "$wrapper" "$system_config"
  rm -rf -- "$temp_dir"
}

if (($# != 1)) || [[ ! "$1" =~ ^[a-z0-9-]+$ ]]; then
  fail 'Usage: bootstrap.sh PROFILE'
fi
PROFILE=$1
if ((EUID == 0)); then
  fail 'Run bootstrap.sh as the target user, not as root; it uses sudo where needed.'
fi
if [[ "$PROFILE" == nixos ]] && ! is_nixos; then
  fail 'The nixos profile needs NixOS. Install NixOS first, or choose another profile.'
fi

ensure_nix
enable_flakes
if [[ "$PROFILE" == nixos ]]; then
  wire_nixos
fi
exec "$REPO_DIR/scripts/switch.sh" "$PROFILE"
