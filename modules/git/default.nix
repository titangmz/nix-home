{ lib, config, ... }:
let
  theme = import ../theme { inherit lib; };
  hex = name: "#${theme.colors.${name}}";
in
{
  programs.git = {
    enable = true;
    settings.include.path = "${config.home.homeDirectory}/.config/git/local";
  };
  home.activation.ensureGitLocal = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    path="${config.home.homeDirectory}/.config/git/local"
    run mkdir -p "$(dirname "$path")"
    if [[ ! -e "$path" ]]; then
      run touch "$path"
    fi
  '';
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          activeBorderColor = [
            (hex "accent")
            "bold"
          ];
          inactiveBorderColor = [ (hex "muted") ];
          optionsTextColor = [ (hex "blue") ];
          selectedLineBgColor = [ (hex "surface") ];
          cherryPickedCommitBgColor = [ (hex "border") ];
          cherryPickedCommitFgColor = [ (hex "accent") ];
          unstagedChangesColor = [ (hex "red") ];
          defaultFgColor = [ (hex "text") ];
          searchingActiveBorderColor = [ (hex "yellow") ];
        };
        authorColors = {
          "*" = hex "lavender";
        };
      };
    };
  };

}
