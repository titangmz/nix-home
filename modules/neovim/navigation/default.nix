{
  imports = [
    ./telescope.nix
    ./neo-tree.nix
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
