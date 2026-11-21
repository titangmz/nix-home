local M = {}
local states = {}
local review_origin = {}
local applying = false
local hooks = {}

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
    local function clean(path)
      path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p")):gsub("/$", "")
      return path == "" and "/" or path
    end
    -- The directory Neovim was started in is the root, repository or not. Only
    -- a file from outside it brings its own: its repository, else its folder.
    local root = clean(vim.fn.getcwd())
    local name = vim.api.nvim_buf_get_name(0)
    if name ~= "" and not vim.startswith(clean(name) .. "/", root == "/" and "/" or root .. "/") then
      local dir = vim.fn.isdirectory(name) == 1 and name or vim.fs.dirname(name)
      root = clean(vim.fs.root(dir, ".git") or dir)
    end
    states[tab] = { root = root, output = false, sizes = {},
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

function M.pane_height()
  return math.max(3, math.min(M.state().sizes.bottom or math.min(16, math.floor(vim.o.lines * 0.25)), vim.o.lines - 14))
end

function M.geometry()
  return { height = M.pane_height(), tools = vim.o.lines >= 20 }
end

-- Panes docked around the editor register here. apply() calls each with the
-- tab's state and geometry, so it shows or hides its own windows.
function M.on_apply(hook) hooks[#hooks + 1] = hook end

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
    for _, hook in ipairs(hooks) do hook(state, geometry) end
    if vim.api.nvim_win_is_valid(focused) then vim.api.nvim_set_current_win(focused)
    else vim.api.nvim_set_current_win(M.main()) end
    -- A terminal restores its input mode on a scheduled callback. Showing a
    -- pane in the background must not put the editor into Insert mode.
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

-- Two layouts. main is the editor, with whatever panes have registered through
-- on_apply docked around it. review is Diffview in its own tab;
-- main closes it and returns to the editor untouched.
function M.layout(name)
  if name == "review" then M.review(); return end
  assert(name == "main", "Unknown workspace layout: " .. tostring(name))
  M.prepare()
  M.apply()
end

function M.tree_popup_size()
  return { width = math.max(20, math.min(64, vim.o.columns - 8)),
    height = math.max(8, math.floor(vim.o.lines * 0.8)) }
end

-- Key hints for the tree popup's bottom border, longest first; the popup shows
-- the longest that fits its width.
M.tree_hints = {
  " a file · A folder · r rename · d delete · ? help ",
  " a · A · r · d · ? help ",
  " ? help ",
}

function M.tree_popup_border()
  local room, hint = M.tree_popup_size().width - 4, M.tree_hints[#M.tree_hints]
  for _, text in ipairs(M.tree_hints) do
    if vim.fn.strdisplaywidth(text) <= room then hint = text; break end
  end
  local Text = require("nui.text")
  return { style = "rounded", highlight = "NeoTreeFloatBorder", text = {
    top = Text(" Files ", "NeoTreeFloatTitle"), top_align = "center",
    bottom = Text(hint, "NeoTreeFloatHint"), bottom_align = "center" } }
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

-- Every editor window starts with a header row. With one window it is blank,
-- a gap between the code and whatever sits above Neovim, such as a tmux status
-- bar. With splits it names each window's file, the current one highlighted.
M.winbar_expr = "%{%v:lua.require'workspace'.winbar()%}"

function M.winbar()
  local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local tab = vim.api.nvim_win_get_tabpage(win)
  local editors = 0
  for _, other in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if normal_window(other) then editors = editors + 1 end
  end
  if editors < 2 then return "" end
  local buf = vim.api.nvim_win_get_buf(win)
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
  if name == "" then name = "[No Name]" end
  local ok, devicons = pcall(require, "nvim-web-devicons")
  local icon = ok and devicons.get_icon(name, nil, { default = true }) or ""
  local hl = win == vim.api.nvim_get_current_win() and "WinBarFileActive" or "WinBarFile"
  local label = " " .. icon .. " " .. name .. (vim.bo[buf].modified and " ●" or "") .. " "
  return "%=%#" .. hl .. "#" .. label:gsub("%%", "%%%%") .. "%*%="
end

local function set_winbars()
  local tab = vim.api.nvim_get_current_tabpage()
  -- Diffview aligns its panes line by line; a header on only some would skew them.
  if review_origin[tab] then return end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if normal_window(win) and vim.wo[win].winbar ~= M.winbar_expr then vim.wo[win].winbar = M.winbar_expr end
  end
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

-- The tree marks its current row with the cursor line, so the terminal cursor
-- is hidden there. Nvim hides it when 'guicursor' uses a group with blend=100.
-- It comes back on leaving the tree and for the command line.
local saved_guicursor
local function hide_cursor(hide)
  if hide and not saved_guicursor then
    saved_guicursor = vim.o.guicursor
    vim.o.guicursor = "a:WorkspaceHiddenCursor"
  elseif not hide and saved_guicursor then
    vim.o.guicursor = saved_guicursor
    saved_guicursor = nil
  end
end

function M.cursor_hidden() return saved_guicursor ~= nil end

function M.setup()
  local function hidden_cursor_group()
    vim.api.nvim_set_hl(0, "WorkspaceHiddenCursor", { blend = 100, nocombine = true })
  end
  hidden_cursor_group()
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
  vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter", "WinNew", "WinEnter", "FileType" }, {
    group = group, callback = set_winbars })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = hidden_cursor_group })
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType", "CmdlineLeave" }, { group = group,
    callback = function() hide_cursor(vim.bo.filetype == "neo-tree") end })
  vim.api.nvim_create_autocmd("CmdlineEnter", { group = group, callback = function() hide_cursor(false) end })
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
