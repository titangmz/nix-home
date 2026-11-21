-- Rust on top of the task pane. rust-analyzer says what is runnable at the
-- cursor, so run and test pick the right package, binary, and test in any
-- workspace layout. Outside a Rust buffer they fall back to plain Cargo.
local M = {}
local task = require("workspace.task")
local workspace = require("workspace")

local function resolve(path, cwd)
  if path:sub(1, 1) == "/" then return path end
  -- Cargo prints paths from the workspace root, which may sit above the package.
  local dir = cwd
  while dir do
    if vim.fn.filereadable(dir .. "/" .. path) == 1 then return dir .. "/" .. path end
    local parent = vim.fs.dirname(dir)
    dir = parent ~= dir and parent or nil
  end
  return cwd .. "/" .. path
end

-- Compiler diagnostics and panics from Cargo's output, as quickfix items.
function M.parse(lines, spec)
  local items, pending, panic = {}, nil, nil
  for _, line in ipairs(lines) do
    local file, lnum, col = line:match("^%s*%-%-> (.-):(%d+):(%d+)")
    if panic then
      panic.text = vim.trim(line) ~= "" and vim.trim(line) or panic.text
      items[#items + 1], panic = panic, nil
    elseif file and pending then
      items[#items + 1] = { filename = resolve(file, spec.cwd), lnum = tonumber(lnum), col = tonumber(col),
        text = pending.text, type = pending.type }
    else
      file, lnum, col = line:match("panicked at (.-):(%d+):(%d+):%s*$")
      if file then
        panic = { filename = resolve(file, spec.cwd), lnum = tonumber(lnum), col = tonumber(col),
          text = "panicked", type = "E" }
      end
    end
    -- A location belongs to the header on the line right above it.
    local kind, text = line:match("^(%a+)%b[]: (.*)$")
    if not kind then kind, text = line:match("^(%a+): (.*)$") end
    pending = (kind == "error" or kind == "warning") and { type = kind == "error" and "E" or "W", text = text } or nil
  end
  if panic then items[#items + 1] = panic end
  return items
end

local function cargo_root()
  local name = vim.api.nvim_buf_get_name(0)
  local root = workspace.root()
  local dir = (vim.bo.buftype == "" and name ~= "") and vim.fs.dirname(name) or root
  return vim.fs.root(dir, "Cargo.toml") or (vim.fn.filereadable(root .. "/Cargo.toml") == 1 and root or nil)
end

-- opts.quiet: keep the pane out of the way unless the task is slow or fails.
function M.cargo(args, opts)
  local root = cargo_root()
  if not root then vim.notify("No Cargo.toml above this file", vim.log.levels.WARN); return false end
  local cmd = { "cargo" }
  vim.list_extend(cmd, args)
  return task.run({ name = "cargo " .. args[1], cmd = cmd, cwd = root, parse = M.parse,
    quiet = opts and opts.quiet })
end

local function is_test(runnable)
  local args = runnable.args and runnable.args.cargoArgs or {}
  return args[1] == "test"
end

local function start(runnable)
  local command, args, cwd, env = require("rustaceanvim.runnables").get_command(runnable)
  local cmd = { command }
  vim.list_extend(cmd, args)
  return task.run({ name = runnable.label, cmd = cmd, cwd = cwd, env = env, parse = M.parse,
    quiet = is_test(runnable) })
end

-- Calls back with rust-analyzer's runnables for this buffer. False when no
-- analyzer is attached, so the caller can fall back.
local function with_runnables(callback)
  local ok, analyzer = pcall(require, "rustaceanvim.rust_analyzer")
  if not ok or vim.bo.filetype ~= "rust" or #analyzer.get_active_rustaceanvim_clients(0) == 0 then return false end
  local params = { textDocument = vim.lsp.util.make_text_document_params(0), position = nil }
  analyzer.buf_request(0, "experimental/runnables", params, function(_, result)
    callback(result or {}, require("rustaceanvim.runnables").get_runnable_at_cursor_position(result or {}))
  end)
  return true
end

-- The runnable under the cursor; otherwise the package's binary.
function M.run()
  return with_runnables(function(runnables, at)
    if at then return start(runnables[at]) end
    local binaries = vim.tbl_filter(function(runnable)
      return runnable.args and runnable.args.cargoArgs and runnable.args.cargoArgs[1] == "run"
    end, runnables)
    if #binaries == 1 then return start(binaries[1]) end
    if #binaries == 0 then return M.cargo({ "run" }) end
    vim.ui.select(binaries, { prompt = "Run", format_item = function(runnable) return runnable.label end },
      function(choice) if choice then start(choice) end end)
  end) or M.cargo({ "run" })
end

-- The test or test module under the cursor; otherwise the package's tests.
function M.test()
  return with_runnables(function(runnables, at)
    if at and is_test(runnables[at]) then return start(runnables[at]) end
    for _, runnable in ipairs(runnables) do
      if not runnable.location and is_test(runnable) then return start(runnable) end
    end
    M.cargo({ "test" }, { quiet = true })
  end) or M.cargo({ "test" }, { quiet = true })
end

function M.test_all() return M.cargo({ "test", "--workspace" }, { quiet = true }) end
function M.check() return M.cargo({ "clippy", "--workspace", "--all-targets" }, { quiet = true }) end

local function rust_lsp(...)
  if vim.fn.exists(":RustLsp") ~= 2 then
    vim.notify("Open a Rust file first", vim.log.levels.WARN); return
  end
  vim.cmd.RustLsp({ args = { ... } })
end

function M.debug() rust_lsp("debug") end
function M.expand_macro() rust_lsp("expandMacro") end
function M.explain_error() rust_lsp("explainError", "current") end

-- rustaceanvim's own pickers (:RustLsp runnables, testables) run here too.
M.executor = {
  execute_command = function(command, args, cwd, opts)
    local cmd = { command }
    vim.list_extend(cmd, args)
    task.run({ name = command .. " " .. (args[1] or ""), cmd = cmd, cwd = cwd, env = opts and opts.env,
      parse = M.parse, quiet = args[1] == "test" })
  end,
}

return M
