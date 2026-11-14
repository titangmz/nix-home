# Imported only by the mac profile.
{ lib, ... }:
let
  theme = import ../theme { inherit lib; };
in
{
  home.file."Library/Application Support/com.mitchellh.ghostty/config".text = ''
    background-opacity = ${theme.ghostty.opacity}
    background-blur = ${toString theme.ghostty.blurRadius}
    # Left Option sends Alt, so tmux's Alt+number window keys work. Right
    # Option still types special characters.
    macos-option-as-alt = left
  '';
}
