{ pkgs, ... }:
let
  map = key: picker: desc: {
    mode = "n";
    inherit key;
    action = "<cmd>lua require('workspace').pick('${picker}')<CR>";
    options = {
      silent = true;
      inherit desc;
    };
  };
in
{
  programs.nixvim = {
    # Text search and the hidden-files picker run these; the editor carries
    # them so it does not depend on the shell's PATH.
    extraPackages = [
      pkgs.ripgrep
      pkgs.fd
    ];
    plugins.telescope = {
      enable = true;
      settings.defaults = {
        sorting_strategy = "ascending";
        # Side-by-side preview on wide screens, stacked on narrow ones, and no
        # preview at all when the window is too short to fit it.
        layout_strategy = "flex";
        layout_config = {
          prompt_position = "top";
          width = 0.9;
          height = 0.85;
          flex.flip_columns = 120;
          horizontal = {
            preview_width = 0.55;
            preview_cutoff = 100;
          };
          vertical = {
            mirror = true;
            preview_cutoff = 25;
            preview_height = 0.45;
          };
        };
        path_display = [ "filename_first" ];
        prompt_prefix = "   ";
        selection_caret = "▍ ";
        set_env.COLORTERM = "truecolor";
        mappings.i = {
          "<C-j>".__raw = "require('telescope.actions').move_selection_next";
          "<C-k>".__raw = "require('telescope.actions').move_selection_previous";
          "<Esc>".__raw = "require('telescope.actions').close";
          "<C-v>".__raw = "require('telescope.actions').select_vertical";
          "<C-x>".__raw = "require('telescope.actions').select_horizontal";
        };
      };
    };
    keymaps = [
      (map "<leader>ff" "find_files" "Find project files")
      (map "<leader>fF" "all_files" "Find hidden and ignored files")
      (map "<leader>fg" "live_grep" "Search project text")
      (map "<leader>fG" "all_grep" "Search hidden and ignored text")
      (map "<leader>fw" "grep_string" "Search word under cursor")
      (map "<leader>fb" "buffers" "Find buffers")
      (map "<leader>fs" "lsp_document_symbols" "Document symbols")
      (map "<leader>fS" "lsp_dynamic_workspace_symbols" "Workspace symbols")
      (map "<leader>fc" "commands" "Find commands")
      (map "<leader>fh" "command_history" "Command history")
      (map "<leader>fk" "keymaps" "Find keymaps")
      (map "<leader>fr" "oldfiles" "Recent files")
      (map "<leader>fR" "resume" "Resume last search")
      (map "<leader>fd" "diagnostics" "Workspace diagnostics")
    ];
  };
}
