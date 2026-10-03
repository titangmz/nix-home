{
  programs.nixvim.plugins.lualine = {
    enable = true;
    settings = {
      options = {
        theme = "catppuccin";
        globalstatus = true;
        component_separators = "";
        section_separators = "";
      };
      extensions = [
        "neo-tree"
        "toggleterm"
        "trouble"
      ];
      sections = {
        lualine_a = [ "mode" ];
        lualine_b = [ "branch" ];
        lualine_c = [
          { __raw = "function() return require('workspace').project_name() end"; }
          {
            __unkeyed-1 = "filename";
            path = 1;
          }
        ];
        lualine_x = [
          "diagnostics"
          {
            __raw = "function() local clients = vim.lsp.get_clients({ bufnr = 0 }); return clients[1] and clients[1].name or '' end";
          }
        ];
        lualine_y = [ { __raw = "function() return require('workspace').label() end"; } ];
        lualine_z = [ "location" ];
      };
    };
  };
}
