{
  programs.nixvim = {
    plugins.oil = {
      enable = true;
      settings = {
        default_file_explorer = true;
        skip_confirm_for_simple_edits = true;
        delete_to_trash = true;
        view_options.show_hidden = true;
        win_options = {
          signcolumn = "no";
          wrap = false;
        };
        float = {
          padding = 3;
          max_width = 90;
          border = "rounded";
        };
        keymaps = {
          # Window navigation keeps working inside Oil.
          "<C-h>" = false;
          "<C-l>" = false;
          "<C-s>" = false;
          "<C-v>" = {
            __unkeyed-1 = "actions.select";
            opts.vertical = true;
          };
          "<C-x>" = {
            __unkeyed-1 = "actions.select";
            opts.horizontal = true;
          };
          "<C-r>" = "actions.refresh";
          q = "actions.close";
          "<BS>" = "actions.parent";
          "gh" = "actions.toggle_hidden";
        };
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "-";
        action = "<cmd>Oil<CR>";
        options = {
          silent = true;
          desc = "Edit parent directory";
        };
      }
      {
        mode = "n";
        key = "<leader>-";
        action = "<cmd>lua require('oil').toggle_float()<CR>";
        options = {
          silent = true;
          desc = "Edit parent directory (float)";
        };
      }
    ];
  };
}
