{ lib, pkgs, ... }:

{
  # The bootstrap starts with nixos-rebuild, then uses the flake-based Home
  # Manager switch after this system configuration has been activated.
  nix.settings.experimental-features = lib.mkAfter [
    "nix-command"
    "flakes"
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

  # Audio
  security.rtkit.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
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

  environment.systemPackages = with pkgs; [
    # CLI tools shared by the opted-in NixOS machines.
    git
    curl
    vim
    wget

    kitty
    firefox
    libnotify
    waybar
    rofi
    mako
    hyprpaper
    hyprlock
    hypridle
    thunar
    imv
  ];
}
