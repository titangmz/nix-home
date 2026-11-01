set positional-arguments := true

# List available commands.
default:
    @just --list

# Apply a Home Manager profile. Name it once; later runs reuse it.
switch *args:
    ./switch.sh "$@"

# Build and activate NixOS, then apply the nixos profile.
switch-nixos *args:
    ./switch-nixos.sh "$@"

# First-time setup: install Nix if needed, then apply a profile, for example `just bootstrap server`.
bootstrap profile:
    ./bootstrap.sh "$1"

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
