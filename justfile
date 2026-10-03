set positional-arguments := true

# List available commands.
default:
    @just --list

# Apply the configuration; forward options to Home Manager.
switch *args:
    ./switch.sh "$@"

# Time one real switch, including build and activation output.
benchmark-switch:
    hyperfine --runs 10 --show-output 'just switch'
