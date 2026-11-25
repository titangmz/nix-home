{ pkgs, ... }:
let
  unwrapped = pkgs.nb.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace nb \
        --replace-fail 'for   __editor in atom code emacs hx macdown mate micro nano pico subl vi vim' \
          'for   __editor in atom code emacs hx macdown mate micro nano nvim pico subl vi vim' \
        --replace-fail 'export NB_DEFAULT_TEMPLATE="''${NB_DEFAULT_TEMPLATE:-}"' \
          'export NB_DEFAULT_TEMPLATE="''${NB_DEFAULT_TEMPLATE:-${./templates/note.md}}"'
    '';
  });
  nb = pkgs.symlinkJoin {
    name = "nb-${unwrapped.version}";
    inherit (unwrapped) pname version meta;
    paths = [ unwrapped ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    # Keep the real script named nb: it uses its basename to choose ~/.nbrc.
    # That config is sourced after this default, so explicit choices still win.
    postBuild = ''
      rm "$out/bin/nb"
      makeWrapper ${unwrapped}/bin/nb "$out/bin/nb" --set EDITOR nvim
    '';
  };
in
{
  home.packages = [ nb ];
  xdg.configFile."nb/templates".source = ./templates;
}
