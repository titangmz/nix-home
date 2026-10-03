{
  programs.nixvim = {
    plugins.neo-tree = {
      enable = true;
      settings = {
        sources = [
          "filesystem"
          "buffers"
          "git_status"
        ];
        source_selector = {
          winbar = true;
          statusline = false;
        };
        enable_git_status = true;
        enable_diagnostics = true;
        close_if_last_window = false;
        popup_border_style = "rounded";
        open_files_do_not_replace_types = [
          "terminal"
          "workspace_terminal"
          "trouble"
          "qf"
        ];
        window = {
          position = "left";
          width = 30;
        };
        default_component_configs.indent = {
          with_markers = true;
          with_expanders = true;
        };
        filesystem = {
          bind_to_cwd = false;
          follow_current_file.enabled = true;
          group_empty_dirs = true;
          use_libuv_file_watcher = true;
          filtered_items = {
            hide_dotfiles = false;
            hide_gitignored = true;
            hide_by_name = [ ".git" ];
          };
        };
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>lua require('workspace').toggle_tree()<CR>";
        options = {
          silent = true;
          desc = "Toggle file tree";
        };
      }
      {
        mode = "n";
        key = "<leader>E";
        action = "<cmd>lua require('workspace').reveal()<CR>";
        options = {
          silent = true;
          desc = "Reveal current file";
        };
      }
    ];
  };
}
