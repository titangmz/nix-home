-- The server editor lacks the development tooling. Its workspace must still lay out cleanly.
local function check()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  assert(vim.fn.executable("rust-analyzer") == 0, "Development tooling leaked into the server editor")
  local errors = {}
  vim.notify = function(message, level)
    if level == vim.log.levels.ERROR then table.insert(errors, message) end
  end

  local root = vim.fn.tempname() .. " server project"
  vim.fn.mkdir(root, "p")
  vim.fn.writefile({ "hello" }, root .. "/notes.txt")
  vim.cmd.edit(vim.fn.fnameescape(root .. "/notes.txt"))
  vim.o.columns, vim.o.lines = 200, 50
  require("workspace").layout("main")
  local editor = vim.api.nvim_get_current_win()
  local terminal = require("workspace.terminal")
  terminal.toggle()
  vim.wait(180, function() return false end, 10)
  assert(terminal.popup_open(), "The toggle did not open the shell")
  terminal.toggle()
  vim.wait(180, function() return false end, 10)
  assert(not terminal.popup_open() and vim.api.nvim_get_current_win() == editor, "The toggle did not return to the editor")

  assert(#errors == 0, table.concat(errors, "\n"))
  -- The task pane, the Rust keys, and the debugger belong to workstations.
  assert(not pcall(require, "workspace.task"), "The task pane leaked into the server editor")
  assert(not pcall(require, "dap"), "The debugger leaked into the server editor")
  assert(vim.fn.maparg(" rr", "n") == "" and vim.fn.maparg(" to", "n") == "", "Run keys leaked into the server editor")
  assert(vim.v.errmsg == "", vim.v.errmsg)
end

local ok, err = xpcall(check, debug.traceback)
if not ok then io.stderr:write(err .. "\n"); vim.cmd("cquit 1") end
vim.cmd("qa!")
