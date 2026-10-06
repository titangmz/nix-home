#!/usr/bin/env bash
set -euo pipefail
config_home="@CONFIG_HOME@"
root_file="$config_home/nix-home/root"
hypr_dir="$config_home/hypr"
if [[ ! -r "$root_file" ]]; then
  printf 'Missing %s. Run ./bootstrap-nixos.sh or ./bootstrap-home.sh from the checkout.\n' "$root_file" >&2
  exit 1
fi
root=$(tr -d '\n' < "$root_file")
source="$root/modules/nixos/desktop/hyprland/hyprland.lua"
if [[ ! -f "$source" ]]; then
  printf 'Hyprland config not found at %s\n' "$source" >&2
  exit 1
fi
mkdir -p "$hypr_dir"
tmp="$hypr_dir/style.lua.tmp"
cp -f @STYLE@ "$tmp"
mv -f "$tmp" "$hypr_dir/style.lua"
ln -sfn "$source" "$hypr_dir/hyprland.lua"
