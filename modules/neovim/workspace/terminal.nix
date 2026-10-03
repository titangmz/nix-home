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
    plugins.toggleterm = {
      enable = true;
      settings = {
        direction = "horizontal";
        size.__raw = "function() return require('workspace').terminal_height() end";
        shade_terminals = false;
        start_in_insert = false;
        persist_mode = false;
        persist_size = true;
        close_on_exit = false;
      };
    };
    extraFiles."lua/workspace/terminal.lua".source = ./terminal.lua;
    extraConfigLua = "require('workspace.terminal').setup()";
    keymaps = [
      (map "<leader>tt" "<cmd>lua require('workspace.terminal').toggle()<CR>" "Toggle shell popup")
      (map "<leader>to" "<cmd>lua require('workspace.terminal').toggle_output()<CR>"
        "Toggle read-only terminal output"
      )
      (map "<leader>rr" "<cmd>lua require('workspace.terminal').cargo('run')<CR>" "Cargo run")
      (map "<leader>rc" "<cmd>lua require('workspace.terminal').cargo('check')<CR>" "Cargo check")
      (map "<leader>rt" "<cmd>lua require('workspace.terminal').cargo('test')<CR>" "Cargo test")
    ];
  };
}
