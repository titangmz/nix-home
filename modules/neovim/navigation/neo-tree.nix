let
  map = key: action: desc: {
    mode = "n";
    inherit key action;
    options = {
      silent = true;
      inherit desc;
    };
  };
in
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
        # One clean header: the project root node. No source tabs, no edgy title.
        source_selector = {
          winbar = false;
          statusline = false;
        };
        enable_git_status = true;
        enable_diagnostics = true;
        close_if_last_window = false;
        popup_border_style = "rounded";
        use_popups_for_input = false;
        open_files_do_not_replace_types = [
          "terminal"
          "workspace_terminal"
          "trouble"
          "qf"
          "edgy"
        ];
        default_component_configs = {
          container.enable_character_fade = true;
          indent = {
            indent_size = 2;
            padding = 1;
            with_markers = false;
            with_expanders = true;
            expander_collapsed = "";
            expander_expanded = "";
            expander_highlight = "NeoTreeExpander";
          };
          icon = {
            folder_closed = "";
            folder_open = "";
            folder_empty = "";
            folder_empty_open = "";
            default = "";
          };
          modified.symbol = "●";
          name = {
            trailing_slash = false;
            use_git_status_colors = true;
          };
          # Names are already coloured by Git status; one small mark is enough.
          git_status.symbols = {
            added = "";
            modified = "";
            deleted = "";
            renamed = "";
            untracked = "";
            ignored = "";
            unstaged = "";
            staged = "";
            conflict = "";
          };
          diagnostics.symbols = {
            error = " ";
            warn = " ";
            info = " ";
            hint = " ";
          };
          file_size.enabled = false;
          type.enabled = false;
          last_modified.enabled = false;
          created.enabled = false;
          symlink_target.enabled = false;
        };
        window = {
          # Always a popup, like the Telescope pickers.
          position = "float";
          popup = {
            title = "Files";
            position = "50%";
            size.__raw = ''
              function()
                return { width = math.max(20, math.min(64, vim.o.columns - 8)),
                  height = math.max(8, math.floor(vim.o.lines * 0.8)) }
              end
            '';
          };
          mappings = {
            # Space stays the leader inside the tree.
            "<space>" = "none";
            "<cr>" = "open";
            l = "open";
            h = "close_node";
            o = "open";
            v = "open_vsplit";
            s = "open_split";
            S = "none";
            t = "open_tabnew";
            w = "none";
            P = {
              __unkeyed-1 = "toggle_preview";
              config.use_float = true;
            };
            Y = {
              __raw = ''
                function(state)
                  local path = state.tree:get_node():get_id()
                  vim.fn.setreg("+", path)
                  vim.notify("Copied " .. vim.fn.fnamemodify(path, ":~:."))
                end
              '';
            };
            z = "close_all_nodes";
            Z = "expand_all_nodes";
            e = "none";
            q = "close_window";
            "<" = "prev_source";
            ">" = "next_source";
          };
        };
        filesystem = {
          bind_to_cwd = false;
          follow_current_file = {
            enabled = true;
            leave_dirs_open = false;
          };
          group_empty_dirs = true;
          use_libuv_file_watcher = true;
          # Oil edits directories in place; the tree stays a sidebar.
          hijack_netrw_behavior = "disabled";
          filtered_items = {
            hide_dotfiles = false;
            hide_gitignored = true;
            hide_by_name = [ ".git" ];
            never_show = [ ".DS_Store" ];
          };
        };
      };
    };
    keymaps = [
      (map "<leader><space>" "<cmd>lua require('workspace').toggle_tree()<CR>" "File tree")
    ];
  };
}
