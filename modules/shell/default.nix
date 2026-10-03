{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];

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
    initContent = lib.mkAfter (builtins.readFile ./zshrc);
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

  programs.starship.enable = true;
  xdg.configFile."starship.toml".source = ./starship.toml;
}
