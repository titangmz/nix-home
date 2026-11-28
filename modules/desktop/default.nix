{
  config,
  lib,
  pkgs,
  ...
}:
let
  palette = import ../theme { inherit lib; };
in
{
  imports = [
    ./waybar
    ./rofi
    ./swaync
    ./clipboard
    ./hyprland
    ./hyprlock
    ./kitty
    ./wallpaper
  ];

  config = lib.mkIf pkgs.stdenv.isLinux {
    home.pointerCursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    gtk = {
      enable = true;
      colorScheme = "dark";
      theme = {
        name = "catppuccin-${palette.flavor}-${palette.accent}-standard";
        package = pkgs.catppuccin-gtk.override {
          accents = [ palette.accent ];
          variant = palette.flavor;
          size = "standard";
        };
      };
      # Keep GTK 4 apps on the same theme; 26.05 changed the default to none.
      gtk4.theme = config.gtk.theme;
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          inherit (palette) flavor accent;
        };
      };
      font = {
        name = "Noto Sans";
        size = 10;
        # Installed by nixosModules.desktop (fonts.packages), not the home profile.
        package = null;
      };
    };

    # The standard folders apps use for downloads and saves. Flatpak apps
    # granted xdg-download (such as Chrome) can only reach ~/Downloads when it
    # is named here. Only folders in use are named, so no empty Desktop,
    # Public, or Templates folders appear.
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      download = "$HOME/Downloads";
      pictures = "$HOME/Pictures";
      desktop = null;
      documents = null;
      music = null;
      projects = null;
      publicShare = null;
      templates = null;
      videos = null;
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "image/bmp" = [ "imv.desktop" ];
        "image/gif" = [ "imv.desktop" ];
        "image/jpeg" = [ "imv.desktop" ];
        "image/png" = [ "imv.desktop" ];
        "image/svg+xml" = [ "imv.desktop" ];
        "image/tiff" = [ "imv.desktop" ];
        "image/webp" = [ "imv.desktop" ];
      };
    };

    # Provide Xfconf activation in this Hyprland session without an Xfce desktop.
    home.packages = [ pkgs.xfconf ];
    xdg.dataFile."dbus-1/services/org.xfce.Xfconf.service".text = ''
      [D-BUS Service]
      Name=org.xfce.Xfconf
      Exec=${pkgs.xfconf}/lib/xfce4/xfconf/xfconfd
      SystemdService=xfconfd.service
    '';
    systemd.user.services.xfconfd = {
      Unit.Description = "Xfce configuration service for Thunar";
      Service = {
        Type = "dbus";
        BusName = "org.xfce.Xfconf";
        ExecStart = "${pkgs.xfconf}/lib/xfce4/xfconf/xfconfd";
      };
    };
    # Start the service explicitly on first activation: the running D-Bus
    # daemon may not have discovered the newly installed activation file yet.
    home.activation.startXfconf = lib.hm.dag.entryBetween [ "xfconfSettings" ] [ "reloadSystemd" ] ''
      run ${pkgs.systemd}/bin/systemctl --user start xfconfd.service
    '';

    xfconf.settings.thunar = {
      default-view = "ThunarIconView";
      last-icon-view-zoom-level = "THUNAR_ZOOM_LEVEL_100_PERCENT";
      last-side-pane = "ThunarShortcutsPane";
      last-location-bar = "ThunarLocationButtons";
      last-separator-position = 190;
      last-statusbar-visible = true;
      misc-folders-first = true;
      misc-symbolic-icons-in-toolbar = true;
      shortcuts-icon-size = 24;
    };
  };
}
