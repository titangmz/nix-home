{
  programs.nixvim.plugins = {
    toggleterm = {
      enable = true;
      settings = {
        size = 20;
        hide_numbers = true;
        shade_filetypes = [];
        shade_terminals = true;
        shading_factor = 2;
        start_in_insert = true;
        insert_mappings = true;
        terminal_mappings = true;
        persist_size = true;
        direction = "float";
        close_on_exit = true;
        shell = null;
        float_opts = {
          border = "curved";
          width = 120;
          height = 40;
        };
      };
    };
  };
}

