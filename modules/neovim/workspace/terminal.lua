local M = {}
local shell, return_win
local git_terminals, tails = {}, {}
local refresh_pending = false
local task, task_id, task_output = nil, 0, ""

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

local function output_windows()
  local wins = {}
  if shell and vim.api.nvim_buf_is_valid(shell.bufnr) then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == shell.bufnr
        and vim.api.nvim_win_get_config(win).relative == "" then wins[#wins + 1] = win end
    end
  end
  return wins
end

local function refresh()
  refresh_pending = false
  if not shell or not vim.api.nvim_buf_is_valid(shell.bufnr) then return end
  local lines = vim.api.nvim_buf_get_lines(shell.bufnr, 0, -1, false)
  local last = #lines
  -- Follow the prompt, rather than the empty terminal screen rows below it.
  while last > 1 and lines[last]:match("^%s*$") do last = last - 1 end
  for _, win in ipairs(output_windows()) do
    if not tails[win] or vim.api.nvim_win_get_cursor(win)[1] >= tails[win] - 1 then
      vim.api.nvim_win_set_cursor(win, { last, 0 })
      -- View APIs also work while the other view is in terminal-input mode.
      vim.api.nvim_win_call(win, function()
        vim.fn.winrestview({ lnum = last, col = 0, leftcol = 0, topfill = 0,
          topline = math.max(1, last - vim.api.nvim_win_get_height(win) + 1) })
      end)
    end
    tails[win] = last
  end
end

local function queue_refresh()
  if refresh_pending then return end
  refresh_pending = true
  vim.defer_fn(refresh, 30)
end

function M.popup_open()
  return shell and valid_win(shell.window) or false
end

function M.close_popup(focus_editor)
  if not M.popup_open() then return end
  local win = shell.window
  shell.window = nil
  vim.api.nvim_win_close(win, true)
  if focus_editor ~= false then
    if valid_win(return_win) then vim.api.nvim_set_current_win(return_win) end
    vim.cmd.stopinsert()
  end
  queue_refresh()
  vim.schedule(function() require("workspace").apply() end)
end

local function ensure_shell()
  if shell and vim.fn.jobwait({ shell.job_id }, 0)[1] ~= -1 then
    M.close_popup()
    for _, win in ipairs(output_windows()) do vim.api.nvim_win_close(win, true) end
    if vim.api.nvim_buf_is_valid(shell.bufnr) then vim.api.nvim_buf_delete(shell.bufnr, { force = true }) end
    shell, task = nil, nil
  end
  if not shell then
    shell = { bufnr = vim.api.nvim_create_buf(false, true), dir = require("workspace").root() }
    function shell:is_open() return valid_win(self.window) or false end
    local buf = shell.bufnr
    -- Both views use this native terminal buffer, preserving its VT rendering.
    -- The popup is the only window allowed to enter terminal-input mode.
    vim.api.nvim_buf_call(buf, function()
      shell.job_id = vim.fn.jobstart(vim.o.shell, {
        term = true, cwd = shell.dir,
        on_stdout = function(_, data)
          task_output = (task_output .. table.concat(data, "\n")):sub(-4096)
          for id, code in task_output:gmatch("\27%]51;workspace%-task:(%d+):(%d+)\7") do
            if task and task.id == tonumber(id) then
              task.running, task.exit_code = false, tonumber(code)
            end
          end
          queue_refresh()
        end,
        on_exit = function()
          if task then task.running = false end
          queue_refresh()
        end,
      })
    end)
    assert(shell.job_id > 0, "Could not start the workspace shell")
    vim.bo[buf].filetype = "workspace_terminal"
    vim.bo[buf].bufhidden, vim.bo[buf].swapfile = "hide", false
    vim.bo[buf].readonly, vim.bo[buf].modifiable = true, false
    vim.b[buf].workspace_shell = true
    vim.api.nvim_buf_attach(buf, false, { on_lines = queue_refresh })
    for _, key in ipairs({ "i", "I", "a", "A", "o", "O", "s", "S", "R", "<CR>" }) do
      vim.keymap.set("n", key, function()
        if vim.api.nvim_get_current_win() == shell.window then vim.cmd.startinsert()
        else vim.notify("Terminal output is read only; Space tt opens the shell", vim.log.levels.INFO) end
      end, { buffer = buf, desc = "Input only in the shell popup" })
    end
    vim.keymap.set({ "n", "t" }, "<Esc><Esc>", M.close_popup,
      { buffer = buf, desc = "Close terminal popup" })
  end
  return shell
end

function M.active() return ensure_shell() end
function M.output_buffer() return ensure_shell().bufnr end
function M.task() return task end
function M.is_visible()
  for _, win in ipairs(output_windows()) do
    if vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage() then return true end
  end
  return false
end

local function window_options(win)
  vim.wo[win].number, vim.wo[win].relativenumber = false, false
  vim.wo[win].wrap, vim.wo[win].signcolumn = false, "no"
  vim.wo[win].foldcolumn, vim.wo[win].scrolloff = "0", 0
end

function M.show()
  local term = ensure_shell()
  if not M.is_visible() then
    local win = vim.api.nvim_open_win(term.bufnr, false, {
      split = "below", win = require("workspace").main(),
      height = require("workspace").terminal_height(),
    })
    window_options(win)
    vim.wo[win].winfixheight = true
  end
  queue_refresh()
  return term
end

function M.hide()
  for _, win in ipairs(output_windows()) do
    if vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage() then
      tails[win] = nil
      vim.api.nvim_win_close(win, true)
    end
  end
end

local function popup_config()
  local width = math.max(1, math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.9)))
  local height = math.max(1, math.min(vim.o.lines - 4, math.floor(vim.o.lines * 0.85)))
  return { relative = "editor", style = "minimal", border = "rounded",
    title = "Terminal", title_pos = "center", width = width, height = height,
    row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)) }
end

function M.toggle()
  if M.popup_open() then M.close_popup(); return end
  local workspace = require("workspace")
  workspace.prepare()
  return_win = vim.api.nvim_get_current_win()
  local term = ensure_shell()
  term.window = vim.api.nvim_open_win(term.bufnr, true, popup_config())
  window_options(term.window)
  vim.cmd.startinsert()
end

function M.toggle_output()
  local workspace = require("workspace")
  workspace.prepare()
  local state = workspace.state()
  state.terminal, state.bottom = not M.is_visible(), "terminal"
  workspace.apply()
end

function M.cargo(action)
  assert(vim.tbl_contains({ "run", "check", "test" }, action), "Unknown Cargo task")
  local workspace = require("workspace")
  workspace.prepare()
  local root = workspace.root()
  if vim.fn.filereadable(root .. "/Cargo.toml") ~= 1 then
    vim.notify("No Cargo.toml in workspace root", vim.log.levels.WARN); return false
  end
  local term = ensure_shell()
  if task and task.running then
    vim.notify("A Cargo task is still running; stop it before starting another", vim.log.levels.WARN)
    return false
  end
  task_id = task_id + 1
  task = { id = task_id, action = action, running = true }
  task_output = ""
  local marker = "printf '\\033]51;workspace-task:" .. task_id .. ":%s\\007'"
  local command = "( trap \"" .. marker .. " 130; exit 130\" INT; cd " .. vim.fn.shellescape(root)
    .. " && cargo " .. action .. "; __workspace_exit=$?; " .. marker .. " \"$__workspace_exit\" )\n"
  workspace.state().terminal, workspace.state().bottom = true, "terminal"
  workspace.apply()
  vim.api.nvim_chan_send(term.job_id, command)
  return true
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
  vim.api.nvim_create_autocmd("TermOpen", { group = group, callback = function(opts)
    vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { buffer = opts.buf, desc = "Terminal normal mode" })
  end })
  vim.api.nvim_create_autocmd({ "TermEnter", "WinEnter", "BufEnter" }, {
    group = group, callback = function(opts)
      if shell and opts.buf == shell.bufnr and vim.api.nvim_get_current_win() ~= shell.window then
        vim.cmd.stopinsert()
      end
    end,
  })
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
    queue_refresh()
  end })
end
return M
