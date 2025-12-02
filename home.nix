{ config, pkgs, lib, username ? builtins.getEnv "USER", homeDir ? (
  let
    user = builtins.getEnv "USER";
    isDarwin = pkgs.stdenv.isDarwin;
  in
  if isDarwin then "/Users/${user}" else "/home/${user}"
), ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  # Automatically detect username and construct home directory
  # Works on both Mac and Linux
  # Username and homeDir are passed from flake.nix or fallback to environment
  home.username = username;
  home.homeDirectory = homeDir;

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
	pkgs.sshuttle
	pkgs.rustscan
	pkgs.dysk
	pkgs.netcat
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
  home.file = let
    # Fetch catppuccin tmux plugin (v2.1.3)
    catppuccinTmux = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "tmux";
      rev = "v2.1.3";
      sha256 = "sha256-Is0CQ1ZJMXIwpDjrI5MDNHJtq+R3jlNcd9NXQESUe2w=";
    };
  in {
    ".config/eza/theme.yml".source = ./eza/theme.yml;
    ".config/starship.toml".source = ./starship/starship.toml;
    
    # Install catppuccin tmux plugin manually (recommended method per docs)
    ".config/tmux/plugins/catppuccin/tmux".source = catppuccinTmux;
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
    terminal = "tmux-256color";

    # TPM plugins are managed via tmux.conf, not Nix plugins
    # plugins = with pkgs.tmuxPlugins; [ ... ];

    extraConfig = ''
      # Set default shell to zsh (must be set before loading other config)
      set -g default-shell "${pkgs.zsh}/bin/zsh"
      set -g default-command "${pkgs.zsh}/bin/zsh"

      # Load configuration from tmux.conf file
      ${builtins.readFile ./tmux/tmux.conf}
    '';
  };


  programs.zsh = {
	enable = true;
	

	oh-my-zsh = {
		enable = true;
		plugins = [ "z" ];
	};
	autosuggestion.enable = true;
    	
	syntaxHighlighting.enable = true;
    	history = {
      	size = 10000;
    	};
	

	initContent = builtins.readFile ./zsh/.zshrc;
  };

  programs.bash = {
	enable = true;
	initExtra = "exec zsh";
  };

  programs.starship = {
    enable = true;
  };

  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          activeBorderColor = [ "#cba6f7" "bold" ];
          inactiveBorderColor = [ "#a6adc8" ];
          optionsTextColor = [ "#89b4fa" ];
          selectedLineBgColor = [ "#313244" ];
          cherryPickedCommitBgColor = [ "#45475a" ];
          cherryPickedCommitFgColor = [ "#cba6f7" ];
          unstagedChangesColor = [ "#f38ba8" ];
          defaultFgColor = [ "#cdd6f4" ];
          searchingActiveBorderColor = [ "#f9e2af" ];
        };
        authorColors = {
          "*" = "#b4befe";
        };
      };
    };
  };

  programs.neovim = {
	enable = true;

	# Install the Catppuccin plugin
	plugins = with pkgs.vimPlugins; [
	catppuccin-nvim
	nvim-tree-lua
	nvim-web-devicons
	];

  # Lua config after plugin is loaded
  extraConfig = ''
    lua << EOF
    require("catppuccin").setup({
      flavour = "mocha",
      background = { light = "latte", dark = "mocha" },
      transparent_background = true,
    })
    vim.cmd.colorscheme("catppuccin")
    
    -- Ensure Normal highlight group has transparent background
    vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
    EOF
  '';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
