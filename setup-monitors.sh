#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: setup-monitors.sh LEFT_OUTPUT [RIGHT_OUTPUT ...]

Create a machine-local Hyprland monitor layout. Pass output names in physical
left-to-right order; find them with `hyprctl monitors all`.
EOF
}

if (( $# == 0 )); then
  usage
  exit 2
fi

for output in "$@"; do
  if [[ ! "$output" =~ ^[A-Za-z0-9._:-]+$ ]]; then
    printf 'Invalid output name: %s\n' "$output" >&2
    printf 'Use the connector name shown by `hyprctl monitors all`, such as DP-1.\n' >&2
    exit 2
  fi
done

config_home="${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}"
destination="${NIX_HOME_MONITORS_FILE:-$config_home/hypr/local_monitors.lua}"

if [[ -e "$destination" || -L "$destination" ]]; then
  printf 'Refusing to overwrite existing monitor layout: %s\n' "$destination" >&2
  exit 1
fi

if ! command -v hyprctl >/dev/null; then
  printf 'hyprctl is required; run this command inside the Hyprland session.\n' >&2
  exit 1
fi
if ! command -v jq >/dev/null; then
  printf 'jq is required to select the best mode for each output.\n' >&2
  exit 1
fi

if ! monitor_json=$(hyprctl -j monitors all); then
  printf 'Could not query Hyprland monitors; run this command inside the Hyprland session.\n' >&2
  exit 1
fi

declare -a modes=()
for output in "$@"; do
  best_mode=$(
    jq -r --arg output "$output" '.[] | select(.name == $output) | .availableModes[]' <<< "$monitor_json" |
      while IFS= read -r mode; do
        if [[ "$mode" =~ ^([0-9]+)x([0-9]+)@([0-9.]+)Hz$ ]]; then
          printf '%d %s %s\n' "$(( BASH_REMATCH[1] * BASH_REMATCH[2] ))" "${BASH_REMATCH[3]}" "$mode"
        fi
      done |
      sort -k1,1n -k2,2n |
      tail -n 1 |
      cut -d ' ' -f 3
  )

  if [[ -z "$best_mode" ]]; then
    printf 'Output not found or has no usable modes: %s\n' "$output" >&2
    exit 1
  fi
  modes+=("$best_mode")
done

destination_dir=$(dirname "$destination")
mkdir -p "$destination_dir"
temporary=$(mktemp "$destination_dir/.local_monitors.lua.XXXXXX")
trap 'rm -f "$temporary"' EXIT

{
  cat <<'EOF'
-- Machine-local Hyprland monitor layout.
-- Generated once by setup-monitors.sh; edit this file directly as needed.
-- Outputs are arranged left to right and use the highest refresh rate available
-- at each monitor's maximum resolution.

EOF

  index=0
  for output in "$@"; do
    if (( index == 0 )); then
      position="0x0"
    else
      position="auto-right"
    fi

    cat <<EOF
hl.monitor({
    output = "$output",
    mode = "${modes[index]}",
    position = "$position",
    scale = "auto",
})

EOF
    (( index += 1 ))
  done
} > "$temporary"

chmod 0644 "$temporary"
mv "$temporary" "$destination"
trap - EXIT

printf 'Created %s\n' "$destination"
printf 'Reload Hyprland with: hyprctl reload\n'
