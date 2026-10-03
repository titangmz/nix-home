local M = {}
local function editor()
  local win = vim.api.nvim_get_current_win()
  if vim.bo.buftype ~= "" or vim.bo.filetype == "neo-tree" then win = require("workspace").main() end
  return win, vim.api.nvim_win_get_buf(win)
end

local function render(template)
  local win, buf = editor()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local context = require("sidekick.cli.context").get()
  -- Sidekick normally chooses the most recently visited window. Use this editor
  -- explicitly so rapid layout changes cannot attach a different file.
  context.ctx = { win = win, buf = buf, cwd = require("workspace").root(),
    row = cursor[1], col = cursor[2] + 1 }
  return context:render({ msg = template })
end
local function terminal(create)
  local workspace = require("workspace")
  local Session = require("sidekick.cli.session")
  Session.setup()
  local sid = Session.sid({ tool = "codex", cwd = workspace.root() })
  local t = require("sidekick.cli.terminal").get(sid)
  if create and (not t or not t:is_running()) then
    if t then Session.detach(t); t:close() end
    t = Session.new({ tool = "codex", cwd = workspace.root() })
    Session.attach(t)
  end
  return t
end
function M.get() return terminal(false) end
function M.show(focus, dock)
  local t = terminal(true)
  local workspace = require("workspace")
  dock = dock or workspace.geometry().ai_dock
  if t:is_open() and (t.opts.layout ~= dock
    or vim.api.nvim_win_get_tabpage(t.win) ~= vim.api.nvim_get_current_tabpage()) then t:hide() end
  t.opts.layout = dock
  t.opts.split = { width = dock == "right" and (workspace.state().sizes.right or 50) or 0,
    height = dock == "bottom" and workspace.terminal_height() or 0 }
  if t:buf_valid() then vim.b[t.buf].workspace_dock = dock end
  t:show()
  if focus then t:focus() end
  return t
end
function M.hide()
  local t = terminal(false)
  if t then t:hide() end
end
function M.toggle()
  local workspace = require("workspace")
  workspace.prepare()
  local t = terminal(false)
  workspace.state().ai = not (t and t:is_open())
  workspace.state().bottom = "ai"
  workspace.apply()
  if workspace.state().ai then M.show(true) end
end
function M.send(context)
  -- Render before leaving visual mode or changing the current buffer.
  local _, buf = editor()
  local text
  if context == "file" then
    text = "File: " .. vim.api.nvim_buf_get_name(buf) .. "\n```" .. vim.bo[buf].filetype .. "\n"
      .. table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n```"
  elseif context == "selection" and vim.fn.mode():match("[vV\22]") then
    text = "Selection from " .. vim.api.nvim_buf_get_name(buf) .. "\n```" .. vim.bo[buf].filetype .. "\n"
      .. table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() }), "\n") .. "\n```"
  else text = render("{" .. context .. "}") end
  if not text or text == "" then vim.notify("Nothing to send to Codex"); return end
  if vim.fn.mode():match("[vV\22]") then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  end
  local workspace = require("workspace")
  workspace.prepare()
  workspace.state().ai, workspace.state().bottom = true, "ai"
  workspace.apply()
  local t = M.show(true)
  t:send(text .. "\n") -- Insert context; the user submits the prompt.
end
function M.prompt()
  local prompts = {
    { label = "Explain selection or line", template = "Explain {this}" },
    { label = "Fix diagnostics", template = "Help fix the diagnostics in {file}\n{diagnostics}" },
    { label = "Write tests", template = "Write tests for {this}" },
    { label = "Review file", template = "Review {file} for bugs and improvements" },
  }
  -- Capture the editor context before the picker steals focus.
  for _, p in ipairs(prompts) do p.text = render(p.template) end
  vim.ui.select(prompts, { prompt = "Codex prompt", format_item = function(p) return p.label end }, function(p)
    if not p then return end
    local workspace = require("workspace")
    workspace.prepare()
    workspace.state().ai, workspace.state().bottom = true, "ai"
    workspace.apply()
    M.show(true):send(p.text .. "\n")
  end)
end
function M.setup()
  require("sidekick").setup({
    nes = { enabled = false },
    copilot = { status = { enabled = false } },
    cli = {
      picker = "telescope", watch = true, mux = { enabled = false },
      tools = { codex = { cmd = { "codex" } } },
      win = { layout = "right", split = { width = 50, height = 0 } },
    },
  })
end
return M
