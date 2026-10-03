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
          set -g @catppuccin_window_status_style "rounded"
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
