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
  imports = [ ./terminal.nix ];
  programs.nixvim = {
    extraFiles."lua/workspace/init.lua".source = ./init.lua;
    extraConfigLua = "require('workspace').setup()";
    plugins.edgy = {
      enable = true;
      settings = {
        animate.enabled = false;
        keys = {
          "<c-w>>".__raw = "function() require('workspace').resize('width', 2) end";
          "<c-w><".__raw = "function() require('workspace').resize('width', -2) end";
          "<c-w>+".__raw = "function() require('workspace').resize('height', 2) end";
          "<c-w>-".__raw = "function() require('workspace').resize('height', -2) end";
        };
        options = {
          left.size = 30;
          right.size = 50;
          bottom.size = 8;
        };
        left = [
          {
            ft = "neo-tree";
            title = "Project";
          }
        ];
        right = [
          {
            ft = "sidekick_terminal";
            title = "Codex";
            filter.__raw = "function(buf) return vim.b[buf].workspace_dock ~= 'bottom' end";
          }
        ];
        bottom = [
          {
            ft = "workspace_terminal";
            title = "Terminal · read only";
            filter.__raw = "function(_, win) return vim.api.nvim_win_get_config(win).relative == '' end";
          }
          {
            ft = "trouble";
            title = "Diagnostics";
          }
          {
            ft = "qf";
            title = "Quickfix";
          }
          {
            ft = "sidekick_terminal";
            title = "Codex";
            filter.__raw = "function(buf) return vim.b[buf].workspace_dock == 'bottom' end";
          }
        ];
        wo = {
          winbar = true;
          spell = false;
          signcolumn = "no";
        };
      };
    };
    keymaps = [
      (map "<leader>z" "<cmd>lua require('workspace').focus()<CR>" "Toggle Focus / restore workspace")
      (map "<leader>l1" "<cmd>WorkspaceLayout focus<CR>" "Focus layout")
      (map "<leader>l2" "<cmd>WorkspaceLayout code<CR>" "Code layout")
      (map "<leader>l3" "<cmd>WorkspaceLayout review<CR>" "Review layout")
      (map "<leader>l4" "<cmd>WorkspaceLayout full<CR>" "Full layout")
      (map "<leader>ll" "<cmd>WorkspaceLayout<CR>" "Choose layout")
      (map "<leader>lr" "<cmd>WorkspaceRestore<CR>" "Restore workspace")
    ];
  };
}
