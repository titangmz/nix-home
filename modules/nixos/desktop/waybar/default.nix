{ lib, pkgs, ... }:
let
  palette = import ../../../theme { inherit lib; };
  # Also installed as the `network-menu` command for the control center.
  networkMenu = pkgs.writeShellScript "network-menu" (
    palette.render (builtins.readFile ./network-menu)
  );
  # Waybar 0.15 still sends legacy workspace dispatches. The desktop's
  # Hyprland uses Lua IPC; keep the compatibility patch local to this bar.
  waybar = pkgs.waybar.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./hyprland-lua.patch ];
  });
  commands = {
    rofi = lib.getExe pkgs.rofi;
    kitty = lib.getExe pkgs.kitty;
    pavucontrol = lib.getExe pkgs.pavucontrol;
    wpctl = "${pkgs.wireplumber}/bin/wpctl";
    ip = "${pkgs.iproute2}/bin/ip";
    hyprctl = "${pkgs.hyprland}/bin/hyprctl";
    hyprlock = lib.getExe pkgs.hyprlock;
    systemctl = "${pkgs.systemd}/bin/systemctl";
    sessionMenu = "${./session-menu.ui}";
    swaync = "${pkgs.swaynotificationcenter}/bin/swaync-client";
    # nmcli, rofi, notify-send, and nm-connection-editor come from the session
    # PATH, so nmcli always matches the system's NetworkManager.
    vpnStatus = toString (
      pkgs.writeShellScript "waybar-vpn-status" (palette.render (builtins.readFile ./vpn-status))
    );
    networkMenu = toString networkMenu;
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
    # The scripts module puts ~/.local/bin on PATH for every profile.
    home.file.".local/bin/network-menu".source = networkMenu;
    # Hyprland starts Waybar; do not enable a second systemd service.
  };
}
