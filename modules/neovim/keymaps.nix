let
  mapIn = mode: key: action: desc: {
    inherit mode key action;
    options = {
      silent = true;
      inherit desc;
    };
  };
  map = mapIn "n";
  resize =
    dimension: amount: "<cmd>lua require('workspace').resize('${dimension}', ${toString amount})<CR>";
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
      (map "]b" "<cmd>bnext<CR>" "Next buffer")
      (map "[b" "<cmd>bprevious<CR>" "Previous buffer")
      (map "<leader>bn" "<cmd>enew<CR>" "New buffer")
      (map "<leader>bd" "<cmd>lua Snacks.bufdelete()<CR>" "Close buffer")
      (map "<leader>bo" "<cmd>lua Snacks.bufdelete.other()<CR>" "Close other buffers")
      (map "<leader>bs" "<cmd>write<CR>" "Save buffer")
      (map "<C-s>" "<cmd>write<CR>" "Save buffer")
      (mapIn "x" "<C-s>" "<cmd>write<CR><Esc>" "Save buffer")
      (mapIn "i" "<C-s>" "<cmd>write<CR><Esc>" "Save buffer")
      (map "<Esc>" "<cmd>nohlsearch<CR><Esc>" "Clear search highlight")
      (mapIn "x" "<" "<gv" "Indent left")
      (mapIn "x" ">" ">gv" "Indent right")
      (mapIn "x" "J" ":move '>+1<CR>gv=gv" "Move selection down")
      (mapIn "x" "K" ":move '<-2<CR>gv=gv" "Move selection up")
      (map "<leader>|" "<cmd>vsplit<CR>" "Split right")
      (map "<leader>_" "<cmd>split<CR>" "Split below")
      (map "<leader>wv" "<cmd>vsplit<CR>" "Split vertically")
      (map "<leader>ws" "<cmd>split<CR>" "Split horizontally")
      (map "<leader>wc" "<cmd>close<CR>" "Close window")
      (map "<leader>w=" "<C-w>=" "Equalize windows")
      (map "<leader>w>" (resize "width" 2) "Widen window")
      (map "<leader>w<" (resize "width" (-2)) "Narrow window")
      (map "<leader>w+" (resize "height" 2) "Increase window height")
      (map "<leader>w-" (resize "height" (-2)) "Decrease window height")
      (map "<C-Right>" (resize "width" 4) "Widen window")
      (map "<C-Left>" (resize "width" (-4)) "Narrow window")
      (map "<C-Up>" (resize "height" 2) "Increase window height")
      (map "<C-Down>" (resize "height" (-2)) "Decrease window height")
    ]
    ++
      builtins.concatMap
        (direction: [
          (map "<C-${direction}>" "<C-w>${direction}" "Move to ${direction} pane")
          (mapIn "t" "<C-${direction}>" "<C-\\><C-n><C-w>${direction}" "Move to ${direction} pane")
        ])
        [
          "h"
          "j"
          "k"
          "l"
        ];
  };
}
