{ lib, pkgs, ... }:
let
  user = import ../../profiles/user.nix;
in
{
  # The bootstrap starts with nixos-rebuild, then uses the flake-based Home
  # Manager switch after this system configuration has been activated.
  nix.settings.experimental-features = lib.mkAfter [
    "nix-command"
    "flakes"
  ];

  # Provide the dynamic linker compatibility layer for non-Nix binaries.
  # The Zed Flatpak re-executes its glibc editor on the host. These libraries
  # are the ones that binary loads by soname; GPU drivers still come from
  # /run/opengl-driver.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glib
    alsa-lib
    wayland
    libdrm
    libgbm
    libglvnd
    libx11
    vulkan-loader
  ];

  # Hyprland
  programs.hyprland.enable = true;

  # A small TTY greeter authenticates the user and starts the managed Hyprland
  # session. Keep machine-specific users and automatic login out of this module.
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd /run/current-system/sw/bin/start-hyprland";
  };

  # Home Manager applies the desktop's GTK preferences through DConf before it
  # links the Hyprland configuration. Register DConf on the user D-Bus so that
  # activation cannot stop before linkGeneration.
  programs.dconf.enable = true;

  # Thunar delegates image thumbnail generation to Tumbler; imv remains the
  # default application used when an image is opened.
  services.tumbler.enable = true;

  services.flatpak.enable = true;

  # OpenVPN through NetworkManager: the plugin handles .ovpn connections,
  # nm-applet (started by Hyprland, shown in the Waybar tray) connects them
  # and asks for VPN passwords, and nm-connection-editor imports them.
  # NetworkManager itself is enabled in machine.nix.
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

  # nm-applet saves VPN passwords in the login keyring, unlocked at login.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  services.openssh.enable = true;

  # Docker stays on NixOS. The package includes the Compose plugin, so
  # `docker compose` works. The account itself stays in machine.nix; this
  # module only adds that user to the docker group.
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker.override { composeSupport = true; };
  };
  users.users.${user.username}.extraGroups = [ "docker" ];

  # Audio
  security.rtkit.enable = true;

  # Every desktop font lives here, never in Home Manager. NixOS builds the
  # fontconfig cache with the system, so it always matches the installed files.
  # See README.md, Fonts.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Desktop Portals: file pickers. screen sharing, etc.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  # Bazaar and Warehouse are native clients of the Flatpak service above.
  # They install and manage Flatpak apps; they are not Flatpaks themselves.
  environment.systemPackages = with pkgs; [
    kitty
    firefox
    hyprlock
    hypridle
    networkmanagerapplet
    thunar
    imv
    bazaar
    warehouse
  ];

  # Keep the compositor-matched plugin at a stable path. Hyprland Lua loads it
  # from here; systemPackages does not reliably expose plugin .so files.
  environment.etc."hyprland-plugins/libhyprbars.so".source =
    "${pkgs.hyprlandPlugins.hyprbars}/lib/libhyprbars.so";
}
