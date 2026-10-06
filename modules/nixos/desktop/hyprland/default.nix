{
  config,
  lib,
  pkgs,
  ...
}:
let
  theme = import ../../../theme { inherit lib; };
  styleFile = pkgs.writeText "hypr-style.lua" theme.styleLua;
  linkHyprland = pkgs.writeShellScript "link-hyprland" (
    lib.replaceStrings
      [
        "@CONFIG_HOME@"
        "@STYLE@"
      ]
      [
        config.xdg.configHome
        "${styleFile}"
      ]
      (builtins.readFile ./link-hyprland.sh)
  );
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    # hyprland.lua stays in the checkout so Hyprland can reload it.
    # style.lua is rendered from modules/theme on each activation.
    home.activation.linkHyprland = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${linkHyprland}
    '';
  };
}
