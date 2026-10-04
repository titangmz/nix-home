set positional-arguments := true

# List available commands.
default:
    @just --list

# Apply the configuration; forward options to Home Manager.
switch *args:
    ./switch.sh "$@"

# Opt in to the NixOS Hyprland home configuration.
switch-nixos *args:
    ./switch.sh --profile nixos-hyprland "$@"

# Bootstrap a fresh NixOS machine, then apply the system and desktop home profiles.
bootstrap-nixos:
    ./bootstrap-nixos.sh

# Restart the wallpaper service after changing the local override.
wallpaper:
    systemctl --user restart desktop-wallpaper.service

# Build the NixOS system without activating it.
build-system *args:
    ./rebuild.sh build "$@"

# Apply the NixOS system; Home Manager is switched separately.
switch-system *args:
    sudo ./rebuild.sh switch "$@"

# Time one real switch, including build and activation output.
benchmark-switch:
    hyperfine --runs 10 --show-output 'just switch'
