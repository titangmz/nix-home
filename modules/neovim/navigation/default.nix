{
  imports = [
    ./telescope.nix
    ./neo-tree.nix
    ./oil.nix
  ];
  programs.nixvim = {
    plugins.trouble.enable = true;
    keymaps = [
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<CR>";
        options = {
          silent = true;
          desc = "Toggle workspace diagnostics";
        };
      }
    ];
  };
}
