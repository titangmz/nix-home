# shellcheck shell=bash
# writeShellScript adds the shebang; @NAME@ placeholders are filled by default.nix.
set -euo pipefail

wallpaper='@DEFAULT@'
for wallpaper_override in '@OVERRIDE_PNG@' '@OVERRIDE_JPG@'; do
  if [[ -f "$wallpaper_override" && -r "$wallpaper_override" ]]; then
    wallpaper="$wallpaper_override"
    break
  fi
done

printf 'Using wallpaper: %s\n' "$wallpaper"
wallpaper_config="$XDG_RUNTIME_DIR/desktop-wallpaper/hyprpaper.conf"
# hyprpaper 0.8 syntax: an empty monitor applies the wallpaper to every output.
cat > "$wallpaper_config" <<EOF
wallpaper {
    monitor =
    path = $wallpaper
    fit_mode = cover
}
splash = false
ipc = false
EOF
exec '@HYPRPAPER@' --config "$wallpaper_config"
