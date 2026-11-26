{ lib, pkgs, ... }:
let
  theme = import ../theme { inherit lib; };
  # Full, independent pane outlines are not in a stable tmux release yet.
  tmux = pkgs.tmux.overrideAttrs (old: {
    version = "next-3.9";
    src = pkgs.fetchFromGitHub {
      owner = "tmux";
      repo = "tmux";
      rev = "9db7c8259d15f15575743427b8efb33c622aa9cf";
      hash = "sha256-MvAhOMQV6BRykeim9WZhyjxfU6i0BQTUNy3oUVR/WBo=";
    };
    buildInputs =
      old.buildInputs
      ++ [
        pkgs.libpng
        pkgs.zlib
      ]
      ++ lib.optional pkgs.stdenv.isDarwin pkgs.jemalloc;
    configureFlags = old.configureFlags ++ lib.optional pkgs.stdenv.isDarwin "--enable-jemalloc";
    meta = old.meta // {
      changelog = "https://github.com/tmux/tmux/blob/9db7c8259d15f15575743427b8efb33c622aa9cf/CHANGES";
    };
  });
  catppuccin = pkgs.tmuxPlugins.catppuccin.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./catppuccin-no-popup-style.patch ];
  });
in
{
  programs.tmux = {
    enable = true;
    package = tmux;
    clock24 = true;
    terminal = "tmux-256color";
    shell = "${pkgs.zsh}/bin/zsh";
    baseIndex = 1;
    mouse = true;
    escapeTime = 0;
    sensibleOnTop = true;
    plugins = [
      pkgs.tmuxPlugins.sidebar
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_status_background "none"
          # Rounded tabs on a transparent bar. The built-in "rounded" style
          # paints the corners with the bar color, so draw the caps in the
          # tab's own color over the default background instead.
          set -g @catppuccin_window_status_style "custom"
          set -g @catppuccin_window_left_separator "#[fg=#{@catppuccin_window_number_color},bg=default]#[fg=#{@thm_crust},bg=#{@catppuccin_window_number_color}]"
          set -g @catppuccin_window_middle_separator " "
          set -g @catppuccin_window_right_separator "#[fg=#{@catppuccin_window_text_color},bg=default]#[none]"
          set -g @catppuccin_window_current_left_separator "#[fg=#{@catppuccin_window_current_number_color},bg=default]#[fg=#{@thm_crust},bg=#{@catppuccin_window_current_number_color}]"
          set -g @catppuccin_window_current_middle_separator " "
          set -g @catppuccin_window_current_right_separator "#[fg=#{@catppuccin_window_current_text_color},bg=default]#[none]"
          set -g status-position top
        '';
      }
    ];
    # Home Manager places extraConfig after the plugins have loaded.
    extraConfig = ''
      set -g default-command "${pkgs.zsh}/bin/zsh"
      ${builtins.readFile ./tmux.conf}
      set -g pane-border-style "fg=#${theme.colors.border},bg=default"
      set -g pane-active-border-style "fg=#${theme.colors.accent},bg=default"
      # Copy-mode and mouse selections use the theme's selection colour, not
      # Catppuccin's surface0 grey, which is hard to see on a clear background.
      set -g mode-style "bg=#${theme.colors.selection},fg=#${theme.colors.text},bold"
    '';
  };
}
