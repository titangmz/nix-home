# NixOS

`modules/nixos/system` is imported by the machine's `/etc/nixos/configuration.nix`. It enables flakes, nix-ld, Hyprland, greetd with tuigreet, portals, audio, DConf, Tumbler, and the system session packages: Firefox, Kitty, Thunar, imv, hyprlock, and hypridle. hyprbars is installed at `/etc/hyprland-plugins/libhyprbars.so`.

`modules/nixos/desktop` is the Home Manager half, imported only by `profiles/nixos-hyprland.nix`. It adds GTK, Kitty config, Hyprland, Waybar, Rofi, Mako, and wallpaper.

`./bootstrap-nixos.sh` preserves the generated configuration as `/etc/nixos/machine.nix`, installs a wrapper that imports this module, and applies the system and desktop. Later updates use `just switch-nixos`. Both can be run again.
