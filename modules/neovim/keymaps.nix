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
    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };
    keymaps = [
      (map "<Tab>" "<cmd>bnext<CR>" "Next buffer")
      (map "<S-Tab>" "<cmd>bprevious<CR>" "Previous buffer")
      (map "<leader>bn" "<cmd>enew<CR>" "New buffer")
      (map "<leader>bd" "<cmd>lua Snacks.bufdelete()<CR>" "Close buffer")
      (map "<leader>bs" "<cmd>write<CR>" "Save buffer")
      (map "<leader>wv" "<cmd>vsplit<CR>" "Split vertically")
      (map "<leader>ws" "<cmd>split<CR>" "Split horizontally")
      (map "<leader>wc" "<cmd>close<CR>" "Close window")
      (map "<leader>w=" "<C-w>=" "Equalize windows")
      (map "<leader>w>" "<cmd>lua require('workspace').resize('width', 2)<CR>" "Widen window")
      (map "<leader>w<" "<cmd>lua require('workspace').resize('width', -2)<CR>" "Narrow window")
      (map "<leader>w+" "<cmd>lua require('workspace').resize('height', 2)<CR>" "Increase window height")
      (map "<leader>w-" "<cmd>lua require('workspace').resize('height', -2)<CR>" "Decrease window height")
    ]
    ++
      builtins.concatMap
        (direction: [
          (map "<C-${direction}>" "<C-w>${direction}" "Move to ${direction} pane")
          {
            mode = "t";
            key = "<C-${direction}>";
            action = "<C-\\><C-n><C-w>${direction}";
            options = {
              silent = true;
              desc = "Move to ${direction} pane";
            };
          }
        ])
        [
          "h"
          "j"
          "k"
          "l"
        ];
  };
}
