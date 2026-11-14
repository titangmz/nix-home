let
  map = key: action: desc: {
    mode = "n";
    inherit key action;
    options = {
      silent = true;
      inherit desc;
    };
  };
  # Enter toggles a folder open or closed, and opens a file.
  toggleOrOpen.__raw = ''
    function(state)
      local node = state.tree:get_node()
      local commands = require("neo-tree.sources.filesystem.commands")
      if node.type == "directory" then commands.toggle_node(state) else commands.open(state) end
    end
  '';
  # Prompts start with the target path relative to the project root, so it can
  # be edited: backspace over the last folder to create in its parent instead.
  withPath = command: {
    __unkeyed-1 = command;
    config.show_path = "relative";
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
            position = "50%";
            size.__raw = "function() return require('workspace').tree_popup_size() end";
            # The title on top, the main keys along the bottom edge.
            border.__raw = "function() return require('workspace').tree_popup_border() end";
          };
          mappings = {
            # Space stays the leader inside the tree.
            "<space>" = "none";
            "<cr>" = toggleOrOpen;
            o = toggleOrOpen;
            l = "open";
            h = "close_node";
            a = withPath "add";
            A = withPath "add_directory";
            c = withPath "copy";
            m = withPath "move";
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
          # Every folder on its own row, so the cursor is never on a merged
          # folder/subfolder row that hides which one new files land in.
          group_empty_dirs = false;
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
