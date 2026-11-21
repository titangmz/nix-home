-- One shell in a popup, and Lazygit. The toggle key opens the shell ready for
-- typing and puts the editor back exactly as it was.
local M = {}
local shell, return_win, return_insert
local git_terminals = {}

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function float_opts()
  return {
    border = "curved", title_pos = "center",
    width = function() return math.max(1, math.floor(vim.o.columns * 0.9)) end,
    height = function() return math.max(1, math.floor(vim.o.lines * 0.85)) end,
  }
end

local function popup_config()
  local width = math.max(1, math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.9)))
  local height = math.max(1, math.min(vim.o.lines - 4, math.floor(vim.o.lines * 0.85)))
  return { relative = "editor", style = "minimal", border = "rounded",
    title = " Terminal ", title_pos = "center", width = width, height = height,
    row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)) }
end

function M.popup_open()
  return shell and valid_win(shell.window) or false
end

function M.close_popup(focus_editor)
  if not M.popup_open() then return end
  local win = shell.window
  shell.window = nil
  vim.api.nvim_win_close(win, true)
  local resume = focus_editor ~= false and return_insert or nil
  return_insert = nil
  if focus_editor ~= false then
    if valid_win(return_win) then vim.api.nvim_set_current_win(return_win) end
    vim.cmd.stopinsert()
  end
  vim.schedule(function()
    require("workspace").apply()
    -- Leaving a terminal ends in Normal mode, and the layout settles a tick
    -- later. Only then resume typing, if the toggle was pressed mid-insert.
    if resume then vim.schedule(function()
      if vim.api.nvim_get_current_win() ~= resume.win or not pcall(vim.api.nvim_win_set_cursor, resume.win, resume.cursor) then return end
      vim.cmd(resume.at_end and "startinsert!" or "startinsert")
    end) end
  end)
end

local function discard(term)
  if shell ~= term then return end
  M.close_popup()
  shell = nil
  if vim.api.nvim_buf_is_valid(term.bufnr) then vim.api.nvim_buf_delete(term.bufnr, { force = true }) end
end

local function ensure_shell()
  if shell and vim.fn.jobwait({ shell.job_id }, 0)[1] ~= -1 then discard(shell) end
  if shell then return shell end
  local term = { bufnr = vim.api.nvim_create_buf(false, true), dir = require("workspace").root() }
  function term:is_open() return valid_win(self.window) or false end
  local buf = term.bufnr
  vim.api.nvim_buf_call(buf, function()
    term.job_id = vim.fn.jobstart(vim.o.shell, {
      term = true, cwd = term.dir,
      -- `exit` in the shell closes the popup; the next toggle starts a new one.
      on_exit = function() vim.schedule(function() discard(term) end) end,
    })
  end)
  assert(term.job_id > 0, "Could not start the workspace shell")
  vim.bo[buf].filetype = "workspace_shell"
  vim.bo[buf].bufhidden, vim.bo[buf].swapfile = "hide", false
  for _, key in ipairs(M.toggle_keys) do
    vim.keymap.set({ "n", "t" }, key, M.close_popup, { buffer = buf, desc = "Back to the editor" })
  end
  vim.keymap.set("n", "q", M.close_popup, { buffer = buf, desc = "Back to the editor" })
  shell = term
  return shell
end

-- Ctrl-/ arrives as Ctrl-_ from terminals without the extended key protocol.
M.toggle_keys = { "<C-/>", "<C-_>" }

function M.active() return ensure_shell() end

local function window_options(win)
  vim.wo[win].number, vim.wo[win].relativenumber = false, false
  vim.wo[win].signcolumn, vim.wo[win].foldcolumn = "no", "0"
  vim.wo[win].scrolloff = 0
end

function M.toggle()
  if M.popup_open() then M.close_popup(); return end
  return_win = vim.api.nvim_get_current_win()
  return_insert = nil
  if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
    local cursor = vim.api.nvim_win_get_cursor(return_win)
    return_insert = { win = return_win, cursor = cursor, at_end = cursor[2] >= #vim.api.nvim_get_current_line() }
  end
  local term = ensure_shell()
  term.window = vim.api.nvim_open_win(term.bufnr, true, popup_config())
  window_options(term.window)
  vim.cmd.startinsert()
end

function M.lazygit()
  local workspace = require("workspace")
  local root = workspace.root()
  local term = git_terminals[root]
  if term and term:is_open() then vim.api.nvim_set_current_win(term.window); return end
  workspace.prepare()
  if not vim.fs.root(root, ".git") then vim.notify("This workspace is not a Git repository"); return end
  term = term or require("toggleterm.terminal").Terminal:new({ cmd = "lazygit", dir = root,
    direction = "float", hidden = true, close_on_exit = true,
    display_name = "Lazygit", float_opts = float_opts(),
    on_open = function(t)
      vim.cmd.startinsert()
      vim.keymap.set("n", "q", function() t:close() end, { buffer = t.bufnr, desc = "Return to editor" })
    end,
  })
  git_terminals[root] = term
  term:open()
end

function M.setup()
  local group = vim.api.nvim_create_augroup("workspace_terminal", { clear = true })
  -- Esc Esc leaves terminal input for scrolling and copying, in every terminal.
  vim.api.nvim_create_autocmd("TermOpen", { group = group, callback = function(opts)
    vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { buffer = opts.buf, desc = "Terminal normal mode" })
  end })
  vim.api.nvim_create_autocmd("WinLeave", { group = group, callback = function()
    if M.popup_open() and vim.api.nvim_get_current_win() == shell.window then
      local win = shell.window
      vim.schedule(function()
        if M.popup_open() and shell.window == win and vim.api.nvim_get_current_win() ~= win then
          M.close_popup(false)
        end
      end)
    end
  end })
  vim.api.nvim_create_autocmd("VimResized", { group = group, callback = function()
    if M.popup_open() then vim.api.nvim_win_set_config(shell.window, popup_config()) end
  end })
  -- Start the shell behind the scenes, so the first toggle shows a ready prompt.
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function()
    if #vim.api.nvim_list_uis() == 0 or vim.g.workspace_no_startup then return end
    vim.defer_fn(function() pcall(ensure_shell) end, 300)
  end })
end

return M
