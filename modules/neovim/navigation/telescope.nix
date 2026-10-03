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
    plugins.telescope = {
      enable = true;
      settings.defaults = {
        sorting_strategy = "ascending";
        layout_config.prompt_position = "top";
        set_env.COLORTERM = "truecolor";
      };
    };
    keymaps = [
      (map "<leader>ff" "find_files" "Find project files")
      (map "<leader>fF" "all_files" "Find hidden and ignored files")
      (map "<leader>fg" "live_grep" "Search project text")
      (map "<leader>fG" "all_grep" "Search hidden and ignored text")
      (map "<leader>fb" "buffers" "Find buffers")
      (map "<leader>fs" "lsp_document_symbols" "Document symbols")
      (map "<leader>fS" "lsp_dynamic_workspace_symbols" "Workspace symbols")
      (map "<leader>fc" "commands" "Find commands")
      (map "<leader>fh" "command_history" "Command history")
      (map "<leader>fk" "keymaps" "Find keymaps")
      (map "<leader>fr" "oldfiles" "Recent files")
    ];
  };
}
