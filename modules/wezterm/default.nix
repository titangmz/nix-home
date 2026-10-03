{ lib, pkgs, ... }:
{
  # The pinned programs.wezterm module also installs WezTerm. Manage only its file.
  xdg.configFile."wezterm/wezterm.lua".text =
    lib.replaceStrings
      [ "@zsh@" ]
      [
        "${pkgs.zsh}/bin/zsh"
      ]
      (builtins.readFile ./wezterm.lua);
}
