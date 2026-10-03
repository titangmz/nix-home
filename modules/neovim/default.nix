{
  imports = [
    ./keymaps.nix
    ./editing.nix
    ./navigation
    ./ui
    ./git.nix
    ./languages.nix
    ./workspace
    ./ai
  ];

  programs.nixvim.enable = true;
  programs.nixvim.extraConfigLuaPre = "vim.fn.mkdir(vim.fn.stdpath('data'), 'p')";
}
