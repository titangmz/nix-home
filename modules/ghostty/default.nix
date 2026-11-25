# Configuration only; Ghostty is installed outside Home Manager.
{ lib, pkgs, ... }:
let
  theme = import ../theme { inherit lib; };
  settings = ''
    background-opacity = ${theme.ghostty.opacity}
    selection-background = #${theme.colors.selection}
    selection-foreground = #${theme.colors.text}
  '';
in
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.isLinux {
    xdg.configFile."ghostty/config".text = settings;
  })
  (lib.mkIf pkgs.stdenv.isDarwin {
    home.file."Library/Application Support/com.mitchellh.ghostty/config".text = settings + ''
      background-blur = ${toString theme.ghostty.blurRadius}
      # Left Option sends Alt, so tmux's Alt+number window keys work. Right
      # Option still types special characters.
      macos-option-as-alt = left
    '';
  })
]
