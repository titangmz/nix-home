-- Runs one command at a time in its own terminal buffer, docked under the
-- editor. Focus stays in the editor; the pane shows the output, and a parser
-- can turn that output into a quickfix list.
local M = {}
local workspace = require("workspace")
local current, last
local serial = 0

-- A quiet task shows its pane only once it has run this long.
M.quiet_delay = 800

local function panes(tab)
  local wins = {}
  for _, win in ipairs(tab and vim.api.nvim_tabpage_list_wins(tab) or vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "workspace_task" then wins[#wins + 1] = win end
  end
  return wins
end

local function alive(task)
  return task and vim.api.nvim_buf_is_valid(task.buf)
end

-- A terminal window follows new output only while its cursor is on the last line.
local function follow()
  if not alive(current) then return end
  local line = vim.api.nvim_buf_line_count(current.buf)
  for _, win in ipairs(panes()) do
    if win ~= vim.api.nvim_get_current_win() then vim.api.nvim_win_set_cursor(win, { line, 0 }) end
  end
end

local function show()
  if not alive(current) or #panes(0) > 0 then return end
  local win = vim.api.nvim_open_win(current.buf, false, {
    split = "below", win = workspace.main(), height = workspace.pane_height(),
  })
  vim.wo[win].number, vim.wo[win].relativenumber = false, false
  vim.wo[win].wrap, vim.wo[win].signcolumn = false, "no"
  vim.wo[win].foldcolumn, vim.wo[win].scrolloff = "0", 0
  vim.wo[win].winfixheight = true
  vim.defer_fn(follow, 30)
end

local function hide()
  for _, win in ipairs(panes(0)) do vim.api.nvim_win_close(win, true) end
end

workspace.on_apply(function(state, geometry)
  if state.output and geometry.tools and alive(current) then show() else hide() end
  if state.sizes.bottom then
    for _, win in ipairs(panes(0)) do vim.w[win].edgy_height = state.sizes.bottom end
  end
end)

local function set_output(visible)
  workspace.state().output = visible
  workspace.apply()
end

local function to_editor()
  vim.cmd.stopinsert()
  vim.api.nvim_set_current_win(workspace.main())
end

-- Saving runs the formatters, so what runs is what is on screen.
local function save_all()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified and vim.bo[buf].buftype == ""
      and vim.api.nvim_buf_get_name(buf) ~= "" then
      pcall(vim.api.nvim_buf_call, buf, function() vim.cmd("silent write") end)
    end
  end
end

local function seconds(task)
  return string.format("%.1fs", (vim.uv.hrtime() - task.started) / 1e9)
end

-- Quickfix lists made here carry a marker, so a clean run clears the last
-- task's errors and leaves any other list alone.
local function publish(task, items)
  if #items > 0 then
    vim.fn.setqflist({}, " ", { title = task.name, items = items, context = { workspace_task = true } })
  else
    local context = vim.fn.getqflist({ context = 1 }).context
    if type(context) == "table" and context.workspace_task then
      vim.fn.setqflist({}, "r", { title = task.name, items = {}, context = context })
    end
  end
end

-- What the process wrote, as plain lines. The terminal buffer wraps long lines
-- at the pane's width, which would cut file paths in two.
local function plain_lines(task)
  local text = table.concat(task.chunks)
  text = text:gsub("\27%][^\7\27]*\7", ""):gsub("\27%][^\27]*\27\\", "")
  text = text:gsub("\27%[[0-9;:?]*[ -/]*[@-~]", ""):gsub("\r+\n", "\n")
  local lines = vim.split(text, "\n", { plain = true })
  -- A carriage return alone restarts the line: progress bars are overwritten.
  for index, line in ipairs(lines) do lines[index] = line:match("[^\r]*$") end
  return lines
end

local function finish(task, code)
  task.running, task.exit_code, task.elapsed = false, code, seconds(task)
  if task.timer then
    task.timer:stop()
    if not task.timer:is_closing() then task.timer:close() end
    task.timer = nil
  end
  if current ~= task or not alive(task) then return end
  -- A key pressed in a finished terminal's input mode would wipe its buffer.
  if vim.api.nvim_get_current_buf() == task.buf then vim.cmd.stopinsert() end
  local items = task.spec.parse and task.spec.parse(plain_lines(task), task.spec) or {}
  task.items = items
  if task.spec.parse then publish(task, items) end
  local jump = #items > 0 and (" · " .. #items .. (#items == 1 and " location" or " locations") .. ", ]q to jump") or ""
  if task.stopped then
    vim.notify("Stopped " .. task.name)
  elseif code ~= 0 then
    set_output(true)
    vim.notify("✗ " .. task.name .. " failed after " .. task.elapsed .. jump, vim.log.levels.WARN)
  elseif task.spec.quiet then
    if not task.was_visible and vim.api.nvim_get_current_buf() ~= task.buf then set_output(false) end
    vim.notify("✓ " .. task.name .. " · " .. task.elapsed .. jump)
  end
  follow()
  vim.cmd.redrawstatus()
end

-- spec: name, cmd (a list), cwd, env, quiet (show the pane only when slow or
-- failed, and hide it again on success), parse(lines, spec) -> quickfix items.
function M.run(spec)
  require("workspace.terminal").close_popup()
  workspace.restore()
  save_all()
  local old = current
  local was_visible = #panes(0) > 0
  if old and old.running then
    old.stopped = true
    vim.fn.jobstop(old.job)
  end
  serial = serial + 1
  local task = { id = serial, spec = spec, name = spec.name, running = true, started = vim.uv.hrtime(),
    was_visible = was_visible, buf = vim.api.nvim_create_buf(false, true), chunks = {}, size = 0 }
  local buf = task.buf
  vim.bo[buf].bufhidden, vim.bo[buf].swapfile = "hide", false
  vim.bo[buf].filetype = "workspace_task"
  current, last = task, spec
  for _, win in ipairs(panes()) do vim.api.nvim_win_set_buf(win, buf) end
  if old and vim.api.nvim_buf_is_valid(old.buf) then vim.api.nvim_buf_delete(old.buf, { force = true }) end
  for _, key in ipairs(require("workspace.terminal").toggle_keys) do
    vim.keymap.set({ "n", "t" }, key, to_editor, { buffer = buf, desc = "Back to the editor" })
  end
  vim.keymap.set("n", "q", function() to_editor(); set_output(false) end, { buffer = buf, desc = "Hide the output" })
  if not spec.quiet then set_output(true) end
  local ok, job = pcall(vim.api.nvim_buf_call, buf, function()
    return vim.fn.jobstart(spec.cmd, { term = true, cwd = spec.cwd, env = spec.env,
      -- Kept for the parser, up to a few megabytes of it.
      on_stdout = spec.parse and function(_, data)
        if task.size > 4e6 then return end
        local chunk = table.concat(data, "\n")
        task.chunks[#task.chunks + 1], task.size = chunk, task.size + #chunk
      end or nil,
      -- The last output arrives a moment after the process ends.
      on_exit = function(_, code) vim.defer_fn(function() finish(task, code) end, 60) end })
  end)
  if not ok or job <= 0 then
    task.running, task.exit_code = false, -1
    vim.notify("Could not start " .. spec.name .. (ok and "" or (": " .. tostring(job))), vim.log.levels.ERROR)
    return false
  end
  task.job = job
  if spec.quiet and not task.was_visible then
    task.timer = vim.defer_fn(function()
      task.timer = nil
      if current == task and task.running then set_output(true) end
    end, M.quiet_delay)
  end
  vim.defer_fn(follow, 30)
  vim.cmd.redrawstatus()
  return true
end

function M.rerun()
  if not last then vim.notify("Nothing has run yet"); return false end
  return M.run(last)
end

function M.stop()
  if not (current and current.running) then vim.notify("No task is running"); return end
  current.stopped = true
  vim.fn.jobstop(current.job)
end

function M.toggle()
  if not alive(current) then vim.notify("Nothing has run yet"); return end
  local visible = #panes(0) > 0
  workspace.prepare()
  set_output(not visible)
end

-- Into the pane, for a program that reads input. The toggle key returns.
function M.focus()
  if not alive(current) then vim.notify("Nothing has run yet"); return end
  workspace.prepare()
  set_output(true)
  local win = panes(0)[1]
  if not win then return end
  vim.api.nvim_set_current_win(win)
  if current.running then vim.cmd.startinsert() end
end

function M.task() return current end
function M.is_visible() return #panes(0) > 0 end

function M.status()
  if not current then return "" end
  if current.running then return "● " .. current.name end
  if current.stopped then return "■ " .. current.name end
  return (current.exit_code == 0 and "✓ " or "✗ ") .. current.name
end

return M
