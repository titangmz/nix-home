-- One set of run, test, check, and debug keys for every language. The buffer's
-- filetype picks the language; elsewhere, the nearest project file does.
local M = {}

local by_filetype = {
  rust = "workspace.rust",
  typescript = "workspace.ts", typescriptreact = "workspace.ts",
  javascript = "workspace.ts", javascriptreact = "workspace.ts",
}
local by_project = { ["Cargo.toml"] = "workspace.rust", ["package.json"] = "workspace.ts" }

local function language()
  local module = by_filetype[vim.bo.filetype]
  if not module then
    local name = vim.api.nvim_buf_get_name(0)
    local dir = (vim.bo.buftype == "" and name ~= "") and vim.fs.dirname(name) or require("workspace").root()
    local project = vim.fs.find(vim.tbl_keys(by_project), { upward = true, path = dir, limit = 1 })[1]
    module = project and by_project[vim.fs.basename(project)]
  end
  if not module then
    vim.notify("No Cargo.toml or package.json above this file", vim.log.levels.WARN)
    return nil
  end
  return require(module)
end

for _, action in ipairs({ "run", "test", "test_all", "check", "debug" }) do
  M[action] = function()
    local lang = language()
    return lang and lang[action]() or false
  end
end

return M
