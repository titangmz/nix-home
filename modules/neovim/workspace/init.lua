local M = {}
local states = {}
local review_origin = {}
local applying = false

local function normal_window(win)
  if not vim.api.nvim_win_is_valid(win) then return false end
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.api.nvim_win_get_config(win).relative == ""
    and (vim.bo[buf].buftype == "" or vim.bo[buf].filetype == "oil")
    and vim.bo[buf].filetype ~= "neo-tree"
end

function M.state()
  local tab = vim.api.nvim_get_current_tabpage()
  if review_origin[tab] and vim.api.nvim_tabpage_is_valid(review_origin[tab]) then
    tab = review_origin[tab]
  end
  if not states[tab] then
    local name = vim.api.nvim_buf_get_name(0)
    local dir = name ~= "" and (vim.fn.isdirectory(name) == 1 and name or vim.fs.dirname(name)) or vim.fn.getcwd()
    local root = vim.fs.root(dir, ".git") or dir
    root = vim.fs.normalize(vim.fn.fnamemodify(root, ":p")):gsub("/$", "")
    if root == "" then root = "/" end
    states[tab] = { root = root, terminal = false, sizes = {},
      main = vim.api.nvim_get_current_win(), tab = tab }
    vim.cmd.tcd(vim.fn.fnameescape(root))
  end
  return states[tab]
end

function M.root() return M.state().root end
function M.project_name()
  local tab = vim.api.nvim_get_current_tabpage()
  local state = states[review_origin[tab] or tab]
  return vim.fs.basename(state and state.root or vim.fn.getcwd())
end
function M.label()
  return review_origin[vim.api.nvim_get_current_tabpage()] and "Review" or "Main"
end

function M.main()
  local state = M.state()
  if normal_window(state.main) then return state.main end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if normal_window(win) then state.main = win; return win end
  end
  return vim.api.nvim_get_current_win()
end

function M.terminal_height()
  return math.max(3, math.min(M.state().sizes.bottom or math.min(16, math.floor(vim.o.lines * 0.25)), vim.o.lines - 14))
end

function M.geometry()
  return { height = M.terminal_height(), tools = vim.o.lines >= 20 }
end

-- The main window's file, when it lives inside the project. Revealing anything
-- else would make the tree ask to change its root.
local function current_file()
  local main = M.main()
  local name = vim.api.nvim_buf_get_name(main == vim.api.nvim_get_current_win() and 0 or vim.api.nvim_win_get_buf(main))
  local root = M.state().root
  if name ~= "" and vim.fn.filereadable(name) == 1 and vim.startswith(name, root == "/" and root or root .. "/") then
    return name
  end
end

-- The explorer popup in this tab, if open.
function M.tree_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then return win end
  end
end

function M.apply()
  if applying or review_origin[vim.api.nvim_get_current_tabpage()]
    or require("workspace.terminal").popup_open() then return end
  applying = true
  local ok, err = pcall(function()
    local state, geometry = M.state(), M.geometry()
    local focused = vim.api.nvim_get_current_win()
    local was_insert = vim.api.nvim_get_mode().mode:sub(1, 1) == "i"
    local term = require("workspace.terminal")
    if state.terminal and geometry.tools then term.show() else term.hide() end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
      if ft == "workspace_terminal" and state.sizes.bottom then vim.w[win].edgy_height = state.sizes.bottom end
    end
    if vim.api.nvim_win_is_valid(focused) then vim.api.nvim_set_current_win(focused)
    else vim.api.nvim_set_current_win(M.main()) end
    -- ToggleTerm restores its input mode on a scheduled callback. Opening a
    -- background shell must not put the editor into Insert mode.
    vim.schedule(function()
      if not was_insert and normal_window(vim.api.nvim_get_current_win()) then vim.cmd.stopinsert() end
    end)
  end)
  applying = false
  if not ok then vim.notify(err, vim.log.levels.ERROR) end
end

function M.resize(dimension, amount)
  local win = vim.api.nvim_get_current_win()
  local edgy = require("edgy").get_win(win)
  if edgy then
    edgy:resize(dimension, amount)
    local edge = edgy.view.edgebar.pos
    if dimension == (edge == "bottom" and "height" or "width") then
      M.state().sizes[edge] = vim.w[win]["edgy_" .. dimension]
    end
  else
    local get = vim.api["nvim_win_get_" .. dimension]
    vim.api["nvim_win_set_" .. dimension](win, math.max(3, get(win) + amount))
  end
end

function M.restore()
  local tab = vim.api.nvim_get_current_tabpage()
  local origin = review_origin[tab]
  if origin then
    vim.cmd.DiffviewClose()
    review_origin[tab] = nil
    if vim.api.nvim_tabpage_is_valid(origin) then vim.api.nvim_set_current_tabpage(origin) end
  end
end

function M.prepare()
  M.restore()
  vim.api.nvim_set_current_win(M.main())
end

function M.review(history)
  if review_origin[vim.api.nvim_get_current_tabpage()] and not history then return end
  M.restore()
  local origin, state = vim.api.nvim_get_current_tabpage(), M.state()
  if not vim.fs.root(state.root, ".git") then
    vim.notify("This workspace is not a Git repository", vim.log.levels.INFO); return
  end
  for tab, parent in pairs(review_origin) do
    if parent == origin and vim.api.nvim_tabpage_is_valid(tab) then
      vim.api.nvim_set_current_tabpage(tab); return
    end
  end
  if history then
    local file = vim.api.nvim_buf_get_name(M.main() == vim.api.nvim_get_current_win()
      and 0 or vim.api.nvim_win_get_buf(M.main()))
    if file == "" then vim.notify("Open a file to view its history"); return end
    vim.cmd("DiffviewFileHistory " .. vim.fn.fnameescape(file))
  else vim.cmd("DiffviewOpen -C=" .. vim.fn.fnameescape(state.root)) end
  local tab = vim.api.nvim_get_current_tabpage()
  if tab ~= origin then review_origin[tab] = origin end
end

function M.history() M.review(true) end

-- Two layouts. main is the editor, with the terminal output docked below when
-- Space to or a Cargo task has shown it. review is Diffview in its own tab;
-- main closes it and returns to the editor untouched.
function M.layout(name)
  if name == "review" then M.review(); return end
  assert(name == "main", "Unknown workspace layout: " .. tostring(name))
  M.prepare()
  M.apply()
end

-- The file tree is a popup: it opens at the current file and closes on q,
-- Esc, the same key, or once a file is opened from it.
function M.toggle_tree()
  local win = M.tree_window()
  if win then vim.api.nvim_win_close(win, true); return end
  M.prepare()
  require("neo-tree.command").execute({ action = "focus", source = "filesystem", position = "float",
    dir = M.root(), reveal_file = current_file() })
end

function M.pick(picker)
  local opts = { cwd = M.root() }
  if picker == "all_files" then
    picker = "find_files"
    opts.find_command = { "fd", "--type", "f", "--hidden", "--no-ignore", "--exclude", ".git" }
  elseif picker == "all_grep" then
    picker = "live_grep"
    opts.additional_args = { "--hidden", "--no-ignore", "--glob", "!.git/*" }
  end
  require("telescope.builtin")[picker](opts)
end

function M.setup()
  local layouts = { "main", "review" }
  vim.api.nvim_create_user_command("WorkspaceLayout", function(opts)
    if opts.args ~= "" then M.layout(opts.args); return end
    vim.ui.select(layouts, { prompt = "Workspace layout" }, function(name)
      if name then M.layout(name) end
    end)
  end, { nargs = "?", complete = function() return layouts end })
  vim.api.nvim_create_user_command("WorkspaceRestore", M.restore, {})
  local group = vim.api.nvim_create_augroup("workspace", { clear = true })
  vim.api.nvim_create_autocmd("WinEnter", { group = group, callback = function()
    local win = vim.api.nvim_get_current_win()
    local tab = vim.api.nvim_get_current_tabpage()
    if not review_origin[tab] and states[tab] and normal_window(win) then states[tab].main = win end
  end })
  vim.api.nvim_create_autocmd("VimResized", { group = group, callback = function()
    vim.schedule(M.apply)
  end })
  vim.api.nvim_create_autocmd("TabEnter", { group = group, callback = function()
    local tab = vim.api.nvim_get_current_tabpage()
    if states[tab] and not review_origin[tab] then vim.schedule(M.apply) end
  end })
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function()
    if #vim.api.nvim_list_uis() > 0 and not vim.g.workspace_no_startup then
      vim.schedule(function() M.layout("main") end)
    end
  end })
  vim.api.nvim_create_autocmd("TabClosed", { group = group, callback = function()
    for tab in pairs(states) do
      if not vim.api.nvim_tabpage_is_valid(tab) then states[tab] = nil end
    end
    for tab in pairs(review_origin) do
      if not vim.api.nvim_tabpage_is_valid(tab) then review_origin[tab] = nil end
    end
  end })
end

return M
