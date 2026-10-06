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
printf 'preload = %s\nwallpaper = ,%s\nsplash = false\nipc = off\n' \
  "$wallpaper" "$wallpaper" > "$wallpaper_config"
exec '@HYPRPAPER@' --config "$wallpaper_config"
