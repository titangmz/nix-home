{ lib, pkgs, ... }:
let
  palette = import ./palette.nix { inherit lib; };
in
{
  imports = [
    ./waybar
    ./rofi
    ./mako
    ./hyprland
    ./wallpaper
  ];

  config = lib.mkIf pkgs.stdenv.isLinux {
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
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = palette.flavor;
          accent = palette.accent;
        };
      };
      font = {
        name = "Noto Sans";
        size = 10;
        package = pkgs.noto-fonts;
      };
    };

    # Provide Xfconf activation in this Hyprland session without an Xfce desktop.
    home.packages = [ pkgs.xfce.xfconf ];
    xdg.dataFile."dbus-1/services/org.xfce.Xfconf.service".text = ''
      [D-BUS Service]
      Name=org.xfce.Xfconf
      Exec=${pkgs.xfce.xfconf}/lib/xfce4/xfconf/xfconfd
      SystemdService=xfconfd.service
    '';
    systemd.user.services.xfconfd = {
      Unit.Description = "Xfce configuration service for Thunar";
      Service = {
        Type = "dbus";
        BusName = "org.xfce.Xfconf";
        ExecStart = "${pkgs.xfce.xfconf}/lib/xfce4/xfconf/xfconfd";
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
