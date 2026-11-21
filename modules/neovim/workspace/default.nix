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
          bottom.size = 8;
        };
        bottom = [
          {
            ft = "trouble";
            title = "Diagnostics";
          }
          {
            ft = "qf";
            title = "Quickfix";
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
      (map "<leader>l1" "<cmd>WorkspaceLayout main<CR>" "Main layout")
      (map "<leader>l2" "<cmd>WorkspaceLayout review<CR>" "Git review layout")
    ];
  };
}
