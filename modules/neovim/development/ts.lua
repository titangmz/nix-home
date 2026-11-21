-- TypeScript and JavaScript on top of the task pane. The project decides the
-- tools: its lockfile names the package manager, and what sits in
-- node_modules/.bin names the test runner, the type checker, and the linter.
local M = {}
local task = require("workspace.task")
local workspace = require("workspace")

local function current_file()
  local name = vim.api.nvim_buf_get_name(0)
  return (vim.bo.buftype == "" and name ~= "") and name or nil
end

-- The first of `names` found in `dir` or a directory above it. Monorepos keep
-- lockfiles and node_modules at the top, above the package being edited.
local function upward(dir, names)
  while dir do
    for _, name in ipairs(type(names) == "table" and names or { names }) do
      if vim.uv.fs_stat(dir .. "/" .. name) then return dir .. "/" .. name end
    end
    local parent = vim.fs.dirname(dir)
    dir = parent ~= dir and parent or nil
  end
end

-- The package the current file belongs to.
function M.root()
  local file = current_file()
  local dir = file and vim.fs.dirname(file) or workspace.root()
  local manifest = upward(dir, "package.json")
  return manifest and vim.fs.dirname(manifest) or nil
end

local function tool(root, name) return upward(root, "node_modules/.bin/" .. name) end
local function uses_bun(root) return upward(root, { "bun.lock", "bun.lockb" }) ~= nil end

local function package_manager(root)
  if uses_bun(root) then return "bun" end
  if upward(root, "pnpm-lock.yaml") then return "pnpm" end
  if upward(root, "yarn.lock") then return "yarn" end
  return "npm"
end

local function is_test_file(file)
  local name = vim.fs.basename(file)
  return name:match("%.test%.[cm]?[jt]sx?$") ~= nil or name:match("%.spec%.[cm]?[jt]sx?$") ~= nil
    or file:find("/__tests__/", 1, true) ~= nil
end

local function relative(file, root)
  return vim.startswith(file, root .. "/") and file:sub(#root + 2) or file
end

local function resolve(path, cwd)
  -- Node prints module paths as percent-encoded file: URLs.
  if vim.startswith(path, "file://") then return vim.uri_to_fname(path) end
  return path:sub(1, 1) == "/" and path or (cwd .. "/" .. path)
end

-- Type errors, lint findings, and the project's own frames from a stack
-- trace, as quickfix items.
function M.parse(lines, spec)
  local items, seen, lint_file = {}, {}, nil
  local function add(file, lnum, col, text, kind)
    file = resolve(vim.trim(file), spec.cwd)
    local key = file .. ":" .. lnum
    if seen[key] or vim.fn.filereadable(file) ~= 1 then return end
    seen[key] = true
    items[#items + 1] = { filename = file, lnum = tonumber(lnum), col = tonumber(col), text = vim.trim(text), type = kind }
  end
  local function severity(word) return word:lower():sub(1, 4) == "warn" and "W" or "E" end
  for _, line in ipairs(lines) do
    -- tsc, with and without colours: src/a.ts:3:5 - error TS2322: ... / src/a.ts(3,5): error TS2322: ...
    local file, lnum, col, word, text = line:match("^(.-):(%d+):(%d+) %- (%a+) (TS%d+: .*)$")
    if not file then file, lnum, col, word, text = line:match("^(.-)%((%d+),(%d+)%): (%a+) (TS%d+: .*)$") end
    if file then
      add(file, lnum, col, text, severity(word))
    elseif line:match("^/%S.*$") and vim.fn.filereadable(vim.trim(line)) == 1 then
      -- ESLint prints the file on its own line, then one row per finding.
      lint_file = vim.trim(line)
    else
      lnum, col, word, text = line:match("^%s+(%d+):(%d+)%s+(%a+)%s+(.+)$")
      if lint_file and lnum and (word == "error" or word == "warning") then
        add(lint_file, lnum, col, text, severity(word))
      else
        -- Stack frames: "at fn (/path/a.ts:3:5)", "at file:///path/a.ts:3:5", Vitest's "❯ src/a.ts:3:5".
        file, lnum, col = line:match("^%s+at .-%(?([^%s()]+):(%d+):(%d+)%)?%s*$")
        if not file then file, lnum, col = line:match("❯ ([^%s()]+):(%d+):(%d+)") end
        if file and not file:find("node_modules", 1, true) and not vim.startswith(file, "node:") then
          add(file, lnum, col, line, "E")
        end
      end
    end
  end
  return items
end

local function start(root, name, cmd, quiet)
  return task.run({ name = name, cmd = cmd, cwd = root, parse = M.parse, quiet = quiet })
end

-- The name of the test or suite around the cursor. A call encloses the
-- cursor when nothing between them is indented as little as the call is.
local function test_at_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)
  local limit = math.huge
  for index = #lines, 1, -1 do
    local line = lines[index]
    if vim.trim(line) ~= "" then
      local indent = #line:match("^%s*")
      local call, _, name = line:match("^%s*([%w_.]+)%s*%(%s*([\"'`])(.-)%2")
      local head = call and call:match("^[%w_]+")
      if (head == "it" or head == "test" or head == "describe") and (index == row or indent < limit) then
        return name
      end
      limit = math.min(limit, indent)
    end
  end
end

-- Runners take the name as a regular expression.
local function literal(name)
  return (name:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?|{}\\]", "\\%0"))
end

-- The command for the project's test runner, for one file and one name, a
-- whole file, or everything.
local function test_command(root, file, name)
  local cmd
  local vitest, jest = tool(root, "vitest"), tool(root, "jest")
  if uses_bun(root) then
    cmd = { "bun", "test" }
    if file then cmd[#cmd + 1] = file end
    if name then vim.list_extend(cmd, { "-t", literal(name) }) end
  elseif vitest then
    -- `run`, or Vitest would stay and watch.
    cmd = { vitest, "run" }
    if file then cmd[#cmd + 1] = file end
    if name then vim.list_extend(cmd, { "-t", literal(name) }) end
  elseif jest then
    cmd = { jest }
    if file then vim.list_extend(cmd, { "--runTestsByPath", file }) end
    if name then vim.list_extend(cmd, { "-t", literal(name) }) end
  elseif not file and M.scripts(root).test then
    cmd = { package_manager(root), "test" }
  else
    cmd = { "node", "--test" }
    if name then vim.list_extend(cmd, { "--test-name-pattern", literal(name) }) end
    if file then cmd[#cmd + 1] = file end
  end
  return cmd
end

function M.scripts(root)
  local ok, manifest = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(root .. "/package.json"), "\n"))
  end)
  return ok and type(manifest) == "table" and type(manifest.scripts) == "table" and manifest.scripts or {}
end

local function no_package()
  vim.notify("No package.json above this file", vim.log.levels.WARN)
  return false
end

-- Runs the current file; in a test file, the test under the cursor.
function M.run()
  local file = current_file()
  if not file or not file:match("%.[cm]?[jt]sx?$") then return M.script() end
  if is_test_file(file) then return M.test() end
  local root = M.root() or vim.fs.dirname(file)
  local cmd
  if uses_bun(root) then
    cmd = { "bun", "run", file }
  else
    -- Node runs TypeScript itself by stripping the types; tsx covers what that cannot.
    cmd = { tool(root, "tsx") or "node", file }
  end
  return start(root, "run " .. vim.fs.basename(file), cmd)
end

-- Picks one of the package's scripts. Space rl runs it again without asking.
function M.script()
  local root = M.root()
  if not root then return no_package() end
  local names = vim.tbl_keys(M.scripts(root))
  if #names == 0 then vim.notify("package.json has no scripts", vim.log.levels.WARN); return false end
  table.sort(names)
  local manager = package_manager(root)
  vim.ui.select(names, { prompt = "Run script" }, function(name)
    if name then start(root, manager .. " run " .. name, { manager, "run", name }) end
  end)
  return true
end

-- The test or suite under the cursor in a test file; otherwise every test.
function M.test()
  local file = current_file()
  if not file or not is_test_file(file) then return M.test_all() end
  local root = M.root() or vim.fs.dirname(file)
  local name = test_at_cursor()
  return start(root, "test " .. (name or vim.fs.basename(file)), test_command(root, relative(file, root), name), true)
end

function M.test_all()
  local root = M.root()
  if not root then return no_package() end
  return start(root, "test", test_command(root), true)
end

-- The type checker, then the linter when the project has one set up.
function M.check()
  local file = current_file()
  local root = M.root() or (file and vim.fs.dirname(file))
  if not root then return no_package() end
  local config = upward(root, { "tsconfig.json", "jsconfig.json" })
  if not config then vim.notify("No tsconfig.json above this file", vim.log.levels.WARN); return false end
  local tsc = { tool(root, "tsc") or "tsc", "--noEmit", "-p", config }
  local eslint = tool(root, "eslint")
  local configured = upward(root, { "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", "eslint.config.ts",
    "eslint.config.mts", ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".eslintrc.yml", ".eslintrc.yaml" })
  if not (eslint and configured) then return start(root, "tsc", tsc, true) end
  -- Both run even when the first fails, so one pass lists everything.
  local script = table.concat(vim.tbl_map(vim.fn.shellescape, tsc), " ") .. "; types=$?; "
    .. vim.fn.shellescape(eslint) .. " .; lint=$?; exit $((types | lint))"
  return start(root, "tsc + eslint", { "sh", "-c", script }, true)
end

-- Starts the current file under the debugger.
function M.debug()
  local file = current_file()
  if not file or not file:match("%.[cm]?[jt]sx?$") then
    vim.notify("Open a TypeScript or JavaScript file first", vim.log.levels.WARN); return false
  end
  local ok, dap = pcall(require, "dap")
  if not ok then
    vim.notify("The debugger is turned off in this build", vim.log.levels.WARN); return false
  end
  local root = M.root() or vim.fs.dirname(file)
  dap.run({ type = "pwa-node", request = "launch", name = "Debug " .. vim.fs.basename(file),
    program = file, cwd = root, runtimeExecutable = tool(root, "tsx") or "node", sourceMaps = true,
    skipFiles = { "<node_internals>/**", "**/node_modules/**" } })
  return true
end

-- For conform: Biome where the project is set up for it, otherwise Prettier.
function M.formatters(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  if upward(dir, { "biome.json", "biome.jsonc" }) and (tool(dir, "biome") or vim.fn.executable("biome") == 1) then
    return { "biome" }
  end
  return { "prettier" }
end

return M
