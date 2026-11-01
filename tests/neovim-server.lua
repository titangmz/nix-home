-- The server profile has no AI module. Its workspace must still lay out cleanly.
local function check()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  assert(not pcall(require, "workspace.ai"), "The AI module must not be installed on servers")
  local errors = {}
  vim.notify = function(message, level)
    if level == vim.log.levels.ERROR then table.insert(errors, message) end
  end

  local root = vim.fn.tempname() .. " server project"
  vim.fn.mkdir(root, "p")
  vim.fn.writefile({ "hello" }, root .. "/notes.txt")
  vim.cmd.edit(vim.fn.fnameescape(root .. "/notes.txt"))
  vim.o.columns, vim.o.lines = 200, 50
  require("workspace").layout("full")
  vim.wait(180, function() return false end, 10)

  assert(#errors == 0, table.concat(errors, "\n"))
  assert(require("workspace.terminal").is_visible(), "Full layout did not dock the shell")
  assert(vim.v.errmsg == "", vim.v.errmsg)
end

local ok, err = xpcall(check, debug.traceback)
if not ok then io.stderr:write(err .. "\n"); vim.cmd("cquit 1") end
vim.cmd("qa!")
