set positional-arguments := true

# List available commands.
default:
    @just --list

# Apply the configuration; forward options to Home Manager.
switch *args:
    ./switch.sh "$@"

# Build and activate NixOS, then apply the Hyprland home configuration.
switch-nixos *args:
    ./switch-nixos.sh "$@"

# Bootstrap a fresh NixOS machine, then apply the system and desktop home profiles.
bootstrap-nixos:
    ./bootstrap-nixos.sh

# Restart the wallpaper service after changing the local override.
wallpaper:
    systemctl --user restart desktop-wallpaper.service

# Exit the current Hyprland session.
logout:
    hyprctl dispatch 'hl.dsp.exit()'

# Time one real switch, including build and activation output.
benchmark-switch:
    hyperfine --runs 10 --show-output 'just switch'
