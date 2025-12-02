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
    telescope = { enabled = true },
    lualine = true,
    treesitter = true,
    indent_blankline = { enabled = true },
    noice = true,
    notify = true,
    cmp = true,
    native_lsp = { enabled = true },
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

-- Fast mode switching (no delay on Esc)
vim.opt.timeoutlen = 300   -- Time to wait for mapped sequences
vim.opt.ttimeoutlen = 10   -- Time to wait for key codes (makes Esc instant)

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

-- Toggle focus between nvim-tree and editor
local function toggle_tree_focus()
  local nvim_tree_api = require('nvim-tree.api')
  local current_buf = vim.api.nvim_get_current_buf()
  local current_buf_name = vim.api.nvim_buf_get_name(current_buf)
  if current_buf_name:match("NvimTree_") then
    vim.cmd('wincmd p')  -- Go to previous window
  else
    nvim_tree_api.tree.focus()
  end
end

-- Keybindings
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true, desc = "Toggle file tree" })
vim.keymap.set('n', '<leader>w', toggle_tree_focus, { noremap = true, silent = true, desc = "Toggle focus tree/editor" })
vim.keymap.set('n', '<leader>g', ':LazyGit<CR>', { noremap = true, silent = true, desc = "Open LazyGit" })
vim.keymap.set('n', '<leader>q', ':q!<CR>', { noremap = true, silent = true, desc = "Force quit" })

-- Telescope fuzzy finder
local telescope = require('telescope')
local builtin = require('telescope.builtin')

telescope.setup({
  defaults = {
    file_ignore_patterns = { "node_modules", ".git/" },
    layout_strategy = "horizontal",
    layout_config = {
      horizontal = { preview_width = 0.5 },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
    },
  },
})

-- Load fzf extension for better performance
pcall(telescope.load_extension, 'fzf')

vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find files" })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Live grep" })

-- Lualine statusline with transparent background
local colors = require("catppuccin.palettes").get_palette("mocha")

-- Custom theme with transparent backgrounds
local custom_catppuccin = {
  normal = {
    a = { bg = colors.blue, fg = colors.mantle, gui = "bold" },
    b = { bg = "NONE", fg = colors.blue },
    c = { bg = "NONE", fg = colors.text },
  },
  insert = {
    a = { bg = colors.green, fg = colors.mantle, gui = "bold" },
    b = { bg = "NONE", fg = colors.green },
    c = { bg = "NONE", fg = colors.text },
  },
  visual = {
    a = { bg = colors.mauve, fg = colors.mantle, gui = "bold" },
    b = { bg = "NONE", fg = colors.mauve },
    c = { bg = "NONE", fg = colors.text },
  },
  replace = {
    a = { bg = colors.red, fg = colors.mantle, gui = "bold" },
    b = { bg = "NONE", fg = colors.red },
    c = { bg = "NONE", fg = colors.text },
  },
  command = {
    a = { bg = colors.peach, fg = colors.mantle, gui = "bold" },
    b = { bg = "NONE", fg = colors.peach },
    c = { bg = "NONE", fg = colors.text },
  },
  inactive = {
    a = { bg = "NONE", fg = colors.surface1 },
    b = { bg = "NONE", fg = colors.surface1 },
    c = { bg = "NONE", fg = colors.surface1 },
  },
}

require('lualine').setup({
  options = {
    theme = custom_catppuccin,
    component_separators = { left = '│', right = '│' },
    section_separators = { left = '', right = '' },
    globalstatus = true,
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff' },
    lualine_c = { 'filename' },
    lualine_x = { 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
})

-- Treesitter (better syntax highlighting)
require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
})

-- Indent blankline (indentation guides)
require('ibl').setup({
  indent = { char = '│' },
  scope = { enabled = true },
})

-- LSP Setup
local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Add language servers here as needed:
-- lspconfig.lua_ls.setup({ capabilities = capabilities })
-- lspconfig.pyright.setup({ capabilities = capabilities })
-- lspconfig.ts_ls.setup({ capabilities = capabilities })
-- lspconfig.nil_ls.setup({ capabilities = capabilities })  -- Nix

-- Completion (nvim-cmp)
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
  }),
})

-- Noice (better command line & notifications UI)
require('noice').setup({
  lsp = {
    override = {
      ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
      ['vim.lsp.util.stylize_markdown'] = true,
      ['cmp.entry.get_documentation'] = true,
    },
  },
  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
    lsp_doc_border = true,
  },
})

