{
  config,
  lib,
  ...
}:
let
  scriptsDirectory = ../../scripts;
  scripts = lib.filterAttrs (
    name: type:
    !(lib.hasPrefix "." name)
    && builtins.elem type [
      "regular"
      "symlink"
    ]
  ) (builtins.readDir scriptsDirectory);
in
{
  home.file = lib.mapAttrs' (
    name: _:
    lib.nameValuePair ".local/bin/${name}" {
      source = scriptsDirectory + "/${name}";
    }
  ) scripts;

  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  # Home Manager guards its session-variable script with an inherited marker.
  # A long-lived user manager can therefore give a new shell the marker with an
  # older PATH. Keep the scripts reachable even in that case.
  programs.zsh.envExtra = lib.mkAfter ''
    typeset -U path
    path=("${config.home.homeDirectory}/.local/bin" $path)
    export PATH
  '';
}
