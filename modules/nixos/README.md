# NixOS

`modules/nixos/system` is imported by the machine's `/etc/nixos/configuration.nix`. It enables flakes, nix-ld, Hyprland, greetd with tuigreet, portals, audio, DConf, Tumbler, Flatpak, Docker, and the system session packages: Firefox, Kitty, Thunar, imv, hyprlock, hypridle, nm-applet, Bazaar, and Warehouse. Bazaar and Warehouse are the native Flatpak store and manager. hyprbars is installed at `/etc/hyprland-plugins/libhyprbars.so`.

Docker starts with the system and installs the CLI with the Compose plugin, so `docker compose` is the command. The module adds the user from `profiles/user.nix` to the `docker` group. The account itself stays in `/etc/nixos/machine.nix`. Log in again after switching so the group applies.

nix-ld also exposes glib, alsa-lib, Wayland, libdrm, libgbm, libglvnd, libX11, and the Vulkan loader. The Zed Flatpak leaves its sandbox and runs the bundled editor on the host, and that binary needs those libraries. `system/README.md` is how to find the libraries for any other binary and add them to that list.

`modules/nixos/desktop` is the Home Manager half, imported only by `profiles/nixos.nix`. It adds GTK, Kitty config, Hyprland, the hyprlock style, Waybar, the SwayNC control center, clipboard history, Rofi, and wallpaper.

The desktop module writes `~/.config/user-dirs.dirs` naming only the folders in use, Downloads and Pictures. Apps read it to choose where downloads and saves go. Flatpak apps depend on it: Chrome's Flatpak is granted `xdg-download`, and without this file that permission resolves to nothing, so the sandbox cannot see `~/Downloads` and saves fall back to document-portal paths under `/run/user/1000/doc/`.

`./bootstrap.sh nixos` preserves the generated configuration as `/etc/nixos/machine.nix`, installs a wrapper that imports this module, and applies the system and desktop. Later updates use `just switch`, which switches the system before the desktop. Both can be run again.

## OpenVPN

OpenVPN runs through NetworkManager, which `machine.nix` enables; this module adds its OpenVPN plugin. Hyprland starts `nm-applet` without a tray icon; it only asks for VPN passwords and saves them. The VPN indicator and network menu in Waybar are the controls (see `desktop/waybar/README.md`).

- Import: choose *Edit connections* in the network menu (or *Advanced Network Configuration* in Rofi), press **+**, choose *Import a saved VPN configuration*, and pick the `.ovpn` file. Certificates and keys referenced by the file are copied in.
- Connect: click the VPN indicator in Waybar and select the connection. From a terminal: `nmcli connection up <name>`.
- Passwords go into GNOME Keyring, which greetd unlocks with the login password.

DNS servers set with `networking.nameservers` in `machine.nix` are used ahead of the VPN's. Remove them if VPN-internal names fail to resolve.

After the first switch that adds the plugin, restart NetworkManager (`sudo systemctl reload dbus && sudo systemctl restart NetworkManager`) or reboot. Until then a connection fails with "org.freedesktop.NetworkManager.openvpn not installed".
