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
    plugins = {
      diffview.enable = true;
      gitsigns = {
        enable = true;
        settings.current_line_blame = false;
      };
    };
    keymaps = [
      (map "<leader>gg" "<cmd>lua require('workspace.terminal').lazygit()<CR>" "Open Lazygit")
      (map "<leader>gd" "<cmd>WorkspaceLayout review<CR>" "Review Git changes")
      (map "<leader>gh" "<cmd>lua require('workspace').history()<CR>" "Git file history")
      (map "<leader>gb" "<cmd>Gitsigns toggle_current_line_blame<CR>" "Toggle line blame")
      (map "<leader>gp" "<cmd>Gitsigns preview_hunk<CR>" "Preview hunk")
      (map "<leader>gs" "<cmd>Gitsigns stage_hunk<CR>" "Stage hunk")
      (map "<leader>gu" "<cmd>Gitsigns undo_stage_hunk<CR>" "Undo hunk staging")
      (map "<leader>gR" "<cmd>Gitsigns reset_hunk<CR>" "Reset hunk")
      (map "[h" "<cmd>Gitsigns nav_hunk prev<CR>" "Previous hunk")
      (map "]h" "<cmd>Gitsigns nav_hunk next<CR>" "Next hunk")
    ];
  };
}
