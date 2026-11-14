{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
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
        # The locked nixpkgs supplies Catppuccin v2.1.3 with the same source hash.
        plugin = pkgs.tmuxPlugins.catppuccin;
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
    '';
  };
}
