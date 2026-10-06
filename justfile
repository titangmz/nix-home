set positional-arguments := true

# List available commands.
default:
    @just --list

# Apply the portable Home Manager configuration.
switch *args:
    ./switch.sh "$@"

# Build and activate NixOS, then apply the Hyprland home configuration.
switch-nixos *args:
    ./switch-nixos.sh "$@"

# First-time setup for a Home Manager-only machine.
bootstrap:
    ./bootstrap-home.sh

# First-time setup for a NixOS machine.
bootstrap-nixos:
    ./bootstrap-nixos.sh

# Format Nix files.
fmt:
    nix fmt

# Evaluate and run the repository checks.
check:
    nix flake check "path:{{justfile_directory()}}"

# Reload Hyprland after editing its checkout configuration.
reload:
    hyprctl reload config-only

# Restart the wallpaper service after changing the local override.
wallpaper:
    systemctl --user restart desktop-wallpaper.service

# Create a machine-local monitor layout. Names are optional.
setup-monitors *args:
    ./setup-monitors.sh "$@"

# Exit the current Hyprland session.
logout:
    hyprctl dispatch 'hl.dsp.exit()'

# Time one real switch, including build and activation output.
benchmark-switch:
    hyperfine --runs 10 --show-output 'just switch'
