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
  # Hyprland gives each screen a block of ten workspaces (see
  # ../hyprland/workspaces.lua); tabs show the screen-local number.
  workspaceLabels = builtins.toJSON (
    builtins.listToAttrs (
      builtins.genList (index: {
        name = toString (index + 1);
        value = toString (lib.mod index 10 + 1);
      }) 90
    )
  );
  renderCommands = lib.replaceStrings (map (name: "@${name}@") (builtins.attrNames commands)) (
    builtins.attrValues commands
  );
  renderConfig =
    text: renderCommands (lib.replaceStrings [ ''"@workspaceLabels@"'' ] [ workspaceLabels ] text);
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages =
      with pkgs;
      [
        playerctl
        wireplumber
        pavucontrol
      ]
      ++ [ waybar ];
    xdg.configFile = {
      "waybar/config.jsonc".text = renderConfig (palette.render (builtins.readFile ./config.jsonc));
      "waybar/style.css".text = palette.render (builtins.readFile ./style.css);
    };
    # Hyprland starts Waybar; do not enable a second systemd service.
  };
}
