{
  programs.nixvim = {
    plugins = {
      treesitter = {
        enable = true;

        nixvimInjections = true;

        folding = true;
        settings = {
          indent.enable = true;
          highlight.enable = true;
          # ensure_installed = "all";
          auto_install = true;
        };
      };

      treesitter-refactor = {
        enable = true;
        settings = {
          highlight_definitions = {
            enable = true;
            # Set to false if you have an `updatetime` of ~100.
            clear_on_cursor_move = false;
          };
        };
      };

      hmts.enable = true;
    };
    
    # Don't fold by default - set foldlevelstart to a high value
    # Make everything transparent
    extraConfigLua = ''
      vim.opt.foldlevelstart = 99
      -- Make background transparent
      vim.opt.termguicolors = true
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
      vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
      vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "WinSeparator", { bg = "none" })
    '';
  };
}