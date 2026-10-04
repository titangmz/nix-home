{ pkgs, ... }:

{
  # Hyprland
  programs.hyprland.enable = true;

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
  ];
}
