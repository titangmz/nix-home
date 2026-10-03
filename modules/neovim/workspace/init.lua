local M = {}
local states = {}
local review_origin = {}
local applying = false

local function normal_window(win)
  if not vim.api.nvim_win_is_valid(win) then return false end
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.api.nvim_win_get_config(win).relative == "" and vim.bo[buf].buftype == ""
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
    states[tab] = { root = root, layout = "code", tree = true, terminal = false, ai = false, sizes = {},
      bottom = "terminal", main = vim.api.nvim_get_current_win(), tab = tab }
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
  if review_origin[vim.api.nvim_get_current_tabpage()] then return "Review" end
  if Snacks.zen.win and Snacks.zen.win:valid() then return "Focus" end
  local state = states[vim.api.nvim_get_current_tabpage()]
  return state and state.layout == "full" and "Full" or "Code"
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
  local state = M.state()
  local left, right = state.sizes.left or 30, state.sizes.right or 50
  local tree = state.tree and vim.o.columns >= (state.ai and (84 + left + right) or (82 + left))
  return { tree = tree, ai_dock = vim.o.columns >= (82 + right) and "right" or "bottom",
    height = M.terminal_height(), tools = vim.o.lines >= 20 }
end

local function tree(show, reveal)
  local state = M.state()
  if show then
    require("neo-tree.command").execute({ action = reveal and "focus" or "show",
      source = "filesystem", position = "left", dir = state.root,
      reveal_file = reveal and vim.api.nvim_buf_get_name(M.main() == vim.api.nvim_get_current_win()
        and 0 or vim.api.nvim_win_get_buf(M.main())) or nil })
  else
    require("neo-tree.command").execute({ action = "close", position = "left" })
  end
end

function M.apply()
  if applying or review_origin[vim.api.nvim_get_current_tabpage()]
    or require("workspace.terminal").popup_open()
    or (Snacks.zen.win and Snacks.zen.win:valid()) then return end
  applying = true
  local ok, err = pcall(function()
    local state, geometry = M.state(), M.geometry()
    local focused = vim.api.nvim_get_current_win()
    local was_insert = vim.api.nvim_get_mode().mode:sub(1, 1) == "i"
    tree(geometry.tree)
    local term = require("workspace.terminal")
    local ai = require("workspace.ai")
    local shared = geometry.ai_dock == "bottom" and state.ai and state.terminal
    if state.terminal and geometry.tools and (not shared or state.bottom == "terminal") then
      term.show()
    else term.hide() end
    if state.ai and geometry.tools and (not shared or state.bottom == "ai") then
      ai.show(false, geometry.ai_dock)
    else ai.hide() end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
      local edge = ft == "neo-tree" and "left" or (ft == "sidekick_terminal" and geometry.ai_dock)
        or (ft == "workspace_terminal" and "bottom")
      local size = edge and state.sizes[edge]
      if size then vim.w[win]["edgy_" .. (edge == "bottom" and "height" or "width")] = size end
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
  if Snacks.zen.win and Snacks.zen.win:valid() then Snacks.zen(); return end
  local tab = vim.api.nvim_get_current_tabpage()
  local origin = review_origin[tab]
  if origin then
    vim.cmd.DiffviewClose()
    review_origin[tab] = nil
    if vim.api.nvim_tabpage_is_valid(origin) then vim.api.nvim_set_current_tabpage(origin) end
  end
end

function M.focus()
  if Snacks.zen.win and Snacks.zen.win:valid() then M.restore(); return end
  vim.api.nvim_set_current_win(M.main())
  local chrome = { laststatus = vim.o.laststatus, showtabline = vim.o.showtabline,
    ruler = vim.o.ruler, showcmd = vim.o.showcmd }
  Snacks.zen({
    win = { height = function() return vim.o.lines - vim.o.cmdheight end, row = 0, col = 0 },
    on_open = function()
      vim.o.laststatus, vim.o.showtabline, vim.o.ruler, vim.o.showcmd = 0, 0, false, false
    end,
    on_close = function()
      vim.o.laststatus, vim.o.showtabline = chrome.laststatus, chrome.showtabline
      vim.o.ruler, vim.o.showcmd = chrome.ruler, chrome.showcmd
    end,
  })
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

function M.layout(name)
  if name == "focus" then
    if not (Snacks.zen.win and Snacks.zen.win:valid()) then M.focus() end
    return
  end
  if name == "review" then M.review(); return end
  assert(name == "code" or name == "full", "Unknown workspace layout: " .. tostring(name))
  M.prepare()
  local state = M.state()
  state.layout, state.tree = name, true
  state.terminal, state.ai = name == "full", name == "full"
  state.bottom = "ai"
  M.apply()
end

function M.toggle_tree()
  M.prepare()
  local state = M.state()
  state.tree = not state.tree
  M.apply()
end

function M.reveal()
  M.prepare()
  M.state().tree = true
  -- Explicit reveal works even when the responsive layout normally hides the tree.
  tree(true, true)
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
  local layouts = { "focus", "code", "review", "full" }
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
      vim.schedule(function() M.layout("code") end)
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
