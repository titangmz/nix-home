{
  config,
  lib,
  pkgs,
  ...
}:
let
  palette = import ../nixos/desktop/palette.nix { inherit lib; };
  inherit (palette) colors;
  roundyPrompt = pkgs.fetchFromGitHub {
    owner = "metaory";
    repo = "zsh-roundy-prompt";
    rev = "5b1e8bfb89f2239ff37fd77d53bd1ba5417a7d18";
    hash = "sha256-0X99WOkJC5z7QLmPw9gTVNfSnwuHmdm2RlMRq41+QzE=";
  };
in
{
  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
  ];

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "z" ];
    };
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.size = 10000;
    # Run personal overrides after Home Manager's shell integrations.
    initContent = lib.mkAfter ''
      source ${roundyPrompt}/roundy.zsh

      # Roundy resets its defaults while loading, so apply our shared palette
      # after the source line. Local overrides in zshrc run after these values.
      typeset -gA RT=(
        bg_ok '#${colors.green}'       fg_ok '#${colors.crust}'
        bg_err '#${colors.red}'        fg_err '#${colors.crust}'
        bg_dir '#${colors.accent}'     fg_dir '#${colors.crust}'
        bg_usr '#${colors.blue}'       fg_usr '#${colors.crust}'
        bg_git '#${colors.sapphire}'   fg_git '#${colors.crust}'
        bg_time '#${colors.lavender}'  fg_time '#${colors.crust}'
        icon_ok '✓' icon_err '×' icon_time '󰥔'
      )
      R_MODE=dir-only
      R_CODE=1
      R_MIN=4
      R_USR='%n'

      ${builtins.readFile ./zshrc}
    '';
  };

  programs.bash = {
    enable = true;
    initExtra = lib.mkAfter "exec ${pkgs.zsh}/bin/zsh";
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    # Interactive Bash hands off to Zsh, which initializes Atuin once.
    enableBashIntegration = false;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = false;
      update_check = false;
    };
  };

}
