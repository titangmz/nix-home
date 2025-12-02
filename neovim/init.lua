-- Set space as leader key (must be before any leader mappings)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Catppuccin colorscheme setup
require("catppuccin").setup({
  flavour = "mocha",
  background = { light = "latte", dark = "mocha" },
  transparent_background = true,
  integrations = {
    nvimtree = true,
  },
})
vim.cmd.colorscheme("catppuccin")

-- Ensure Normal highlight group has transparent background
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })

-- nvim-tree setup
-- Disable netrw (recommended by nvim-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Enable 24-bit color
vim.opt.termguicolors = true

require("nvim-tree").setup({
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 30,
    side = "left",
  },
  renderer = {
    group_empty = true,
    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
      },
    },
  },
  filters = {
    dotfiles = false,
  },
  git = {
    enable = true,
    ignore = false,
  },
  actions = {
    open_file = {
      quit_on_open = false,
      resize_window = true,
    },
  },
})

-- Keybindings for nvim-tree
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true, silent = true, desc = "Toggle file tree" })
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true, desc = "Toggle file tree" })
vim.keymap.set('n', '<leader>f', ':NvimTreeFocus<CR>', { noremap = true, silent = true, desc = "Focus file tree" })

-- Window navigation (easier than Ctrl+w)
vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true, silent = true, desc = "Move to left window" })
vim.keymap.set('n', '<C-j>', '<C-w>j', { noremap = true, silent = true, desc = "Move to window below" })
vim.keymap.set('n', '<C-k>', '<C-w>k', { noremap = true, silent = true, desc = "Move to window above" })
vim.keymap.set('n', '<C-l>', '<C-w>l', { noremap = true, silent = true, desc = "Move to right window" })
vim.keymap.set('n', '<leader>w', '<C-w>w', { noremap = true, silent = true, desc = "Toggle between windows" })

-- Lazygit integration
vim.keymap.set('n', '<leader>gg', ':LazyGit<CR>', { noremap = true, silent = true, desc = "Open LazyGit" })
vim.keymap.set('n', '<leader>gc', ':LazyGitCurrentFile<CR>', { noremap = true, silent = true, desc = "LazyGit current file history" })
vim.keymap.set('n', '<leader>gf', ':LazyGitFilter<CR>', { noremap = true, silent = true, desc = "LazyGit filter" })

