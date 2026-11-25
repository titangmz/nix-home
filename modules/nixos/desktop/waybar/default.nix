{ lib, pkgs, ... }:
let
  palette = import ../../../theme { inherit lib; };
  # Waybar 0.15 still sends legacy workspace dispatches. The desktop's
  # Hyprland uses Lua IPC; keep the compatibility patch local to this bar.
  waybar = pkgs.waybar.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./hyprland-lua.patch ];
  });
  commands = {
    rofi = lib.getExe pkgs.rofi;
    kitty = lib.getExe pkgs.kitty;
    btop = lib.getExe pkgs.btop;
    pavucontrol = lib.getExe pkgs.pavucontrol;
    wpctl = "${pkgs.wireplumber}/bin/wpctl";
    ip = "${pkgs.iproute2}/bin/ip";
    hyprctl = "${pkgs.hyprland}/bin/hyprctl";
    hyprlock = lib.getExe pkgs.hyprlock;
    systemctl = "${pkgs.systemd}/bin/systemctl";
    sessionMenu = "${./session-menu.ui}";
  };
  renderConfig = lib.replaceStrings (map (name: "@${name}@") (builtins.attrNames commands)) (
    builtins.attrValues commands
  );
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages =
      with pkgs;
      [
        playerctl
        wireplumber
        pavucontrol
        nerd-fonts.jetbrains-mono
      ]
      ++ [ waybar ];
    xdg.configFile = {
      "waybar/config.jsonc".text = renderConfig (palette.render (builtins.readFile ./config.jsonc));
      "waybar/style.css".text = palette.render (builtins.readFile ./style.css);
    };
    # Hyprland starts Waybar; do not enable a second systemd service.
  };
}
