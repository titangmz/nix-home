let
  # Secondary sections disappear first on narrow windows.
  wide = columns: { __raw = "function() return vim.o.columns >= ${toString columns} end"; };
in
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
        "oil"
        "toggleterm"
        "trouble"
      ];
      sections = {
        lualine_a = [ "mode" ];
        lualine_b = [
          {
            __unkeyed-1 = "branch";
            cond = wide 70;
          }
        ];
        lualine_c = [
          {
            __unkeyed-1.__raw = "function() return require('workspace').project_name() end";
            cond = wide 100;
          }
          {
            __unkeyed-1 = "filename";
            path = 1;
            shorting_target = 30;
            symbols = {
              modified = "●";
              readonly = " ";
            };
          }
        ];
        lualine_x = [
          "diagnostics"
          {
            __unkeyed-1.__raw = "function() local clients = vim.lsp.get_clients({ bufnr = 0 }); return clients[1] and clients[1].name or '' end";
            cond = wide 100;
          }
        ];
        lualine_y = [
          {
            __unkeyed-1.__raw = "function() return require('workspace').label() end";
            cond = wide 80;
          }
        ];
        lualine_z = [ "location" ];
      };
    };
  };
}
