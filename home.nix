{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "xray";
  home.homeDirectory = "/home/xray";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.helloo
	pkgs.zsh
	pkgs.cowsay
	pkgs.lolcat
	pkgs.bat
	pkgs.tree
	pkgs.git
	pkgs.eza
	pkgs.duf
	pkgs.dust
	pkgs.fd
	pkgs.ripgrep
	pkgs.fzf
	pkgs.tldr
	pkgs.lazygit
	pkgs.procs
	pkgs.gping
	pkgs.btop
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {

    ".config/eza/theme.yml".source = ./eza.theme.yml;
    ".config/starship.toml".source = ./starship.toml;
    ".config/lazygit/config.yml".source = ./lazygit.yml;
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/xray/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };
  
  programs.tmux = {
  enable = true;
  clock24 = true;

  plugins = with pkgs.tmuxPlugins; [
    sensible
    yank
    pain-control
    catppuccin
    resurrect
    continuum
  ];

  extraConfig = ''
    set -g mouse on
    set -g history-limit 10000

    # Continuum autosave every 15 minutes
    set -g @continuum-save-interval '15'
    set -g @catppuccin_flavor "frappe"
  '';
};

  programs.zsh = {
	enable = true;
	initContent = builtins.readFile ./zshrc;
  };

  programs.bash = {
	enable = true;
	initExtra = "exec zsh";
  };

  programs.starship = {
	enable = true;
  };

  programs.neovim = {
	enable = true;

	# Install the Catppuccin plugin
	plugins = with pkgs.vimPlugins; [
	catppuccin-nvim
	];

  # Lua config after plugin is loaded
  extraConfig = ''
    lua << EOF
    require("catppuccin").setup({
      flavour = "mocha",
      background = { light = "latte", dark = "mocha" },
    })
    vim.cmd.colorscheme("catppuccin")
    EOF
  '';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
