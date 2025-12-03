{ config, pkgs, lib, username ? builtins.getEnv "USER", homeDir ? (
  let
    user = builtins.getEnv "USER";
    isDarwin = pkgs.stdenv.isDarwin;
  in
  if isDarwin then "/Users/${user}" else "/home/${user}"
), ... }:

{
  # Username and homeDir are passed from flake.nix or fallback to environment
  home.username = username;
  home.homeDirectory = homeDir;

  home.stateVersion = "25.11";

  # Packages
  home.packages = [
	pkgs.zsh
	pkgs.cowsay
	pkgs.lolcat
	pkgs.bat
	pkgs.tree
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

    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];


  # Dotfiles
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
    ".config/tmux/plugins/catppuccin/tmux".source = catppuccinTmux;
  };


  # Session Variables
  home.sessionVariables = {
    # EDITOR = "emacs";
  };
  

  # Programs
  programs.tmux = {
    enable = true;
    clock24 = true;
    terminal = "tmux-256color";

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

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Pedram Parsa";
        email = "titangmz@gmail.com";
      };
    };
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
    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim
      nvim-tree-lua
      nvim-web-devicons
      lazygit-nvim
      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      lualine-nvim
      # LSP & Completion
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip
      # Treesitter
      nvim-treesitter.withAllGrammars
      # UI
      indent-blankline-nvim
      noice-nvim
      nui-nvim
      nvim-notify
    ];
    extraLuaConfig = builtins.readFile ./neovim/init.lua;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
