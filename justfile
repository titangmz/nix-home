set positional-arguments := true

# List available commands.
default:
    @just --list

# Apply a profile; name it once and later runs reuse it. The nixos profile switches the system too.
switch *args:
    ./scripts/switch.sh "$@"

# First-time setup: install Nix if needed, then apply a profile, for example `just bootstrap server`.
bootstrap profile:
    ./bootstrap.sh "$1"

# Delete old generations and everything in the Nix store they alone used. Rollbacks are lost.
clean:
    nix-collect-garbage -d
    # NixOS keeps system generations under root; refresh the boot menu once they are gone.
    if [ -e /etc/NIXOS ]; then sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot; fi

# Update all flake inputs, then run the checks. Switch afterwards to apply.
update:
    nix flake update --flake "path:{{justfile_directory()}}"
    nix flake check "path:{{justfile_directory()}}"

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
    ./scripts/setup-monitors.sh "$@"

# Exit the current Hyprland session.
logout:
    hyprctl dispatch 'hl.dsp.exit()'

# Time one real switch, including build and activation output.
benchmark-switch:
    hyperfine --runs 10 --show-output 'just switch'
