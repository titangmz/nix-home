-- Behavioral checks against the actual generated Nixvim package.
local function settle()
  vim.wait(180, function() return false end, 10)
end
local function check()
  io.stderr:write("neovim: startup\n")
  assert(vim.v.errmsg == "", vim.v.errmsg)
  local workspace = require("workspace")
  local terminal = require("workspace.terminal")
  local function mapping(key, mode)
    return vim.fn.maparg(key:gsub("<leader>", " "), mode or "n", false, true)
  end
  for _, command in ipairs({ "Telescope", "Neotree", "ToggleTerm", "DiffviewOpen",
    "Trouble", "WorkspaceLayout", "WorkspaceRestore", "Oil", "ZkNew", "ZkNotes", "ZkBacklinks", "RenderMarkdown" }) do
    assert(vim.fn.exists(":" .. command) == 2, "Missing command: " .. command)
  end
  for _, key in ipairs({ "<leader>ff", "<leader>fg", "<leader>l1", "<leader>l2",
    "<leader>tt", "<leader>to", "<leader>cf", "<leader>rr", "-", "<leader>-",
    "<leader><space>", "<C-s>", "<leader>nn", "<leader>nd", "<leader>nf", "<leader>np", "<leader>na", "<leader>nx", "<leader>nX", "<leader>nc", "<leader>um" }) do
    assert(not vim.tbl_isempty(mapping(key)), "Missing mapping: " .. key)
  end
  assert(mapping("<leader><space>").rhs:find("toggle_tree", 1, true), "Space Space is not the file tree")
  assert(mapping("<Tab>").rhs == "<cmd>bnext<CR>")
  assert(mapping("<S-Tab>").rhs == "<cmd>bprevious<CR>")
  assert(vim.tbl_isempty(mapping("<leader>q")))
  for _, key in ipairs({ "<leader>z", "<leader>l3", "<leader>l4", "<leader>ll" }) do
    assert(vim.tbl_isempty(mapping(key)), "Removed layout key is still mapped: " .. key)
  end
  assert(vim.tbl_isempty(mapping("<leader>rn")))
  assert(vim.tbl_isempty(mapping("<leader>tn")))
  assert(vim.tbl_isempty(mapping("<leader>ts")))
  -- Action prefixes must not delay longer mappings in the same namespace.
  for _, prefix in ipairs({ "f", "g", "l", "t", "c", "b", "w", "r", "x", "n", "u" }) do
    assert(vim.tbl_isempty(mapping("<leader>" .. prefix)), "Executable prefix: " .. prefix)
  end
  assert(vim.o.termguicolors and vim.o.undofile)
  -- Editor and popups are clear glass. Popups must still hide the code behind
  -- them, which holds only while blending is off.
  local function bg(group) return vim.api.nvim_get_hl(0, { name = group, link = false }).bg end
  for _, group in ipairs({ "Normal", "NormalFloat", "Pmenu", "BlinkCmpMenu", "NeoTreeNormal", "TelescopeNormal" }) do
    assert(bg(group) == nil, "Background is not clear: " .. group)
  end
  assert(vim.o.winblend == 0 and vim.o.pumblend == 0, "Blending lets code show through popups")
  assert(vim.api.nvim_get_hl(0, { name = "FloatBorder", link = false }).fg, "Popup borders have no colour")
  -- The command line is a noice popup in the middle of the screen.
  -- noice skips its own setup without a UI, so check that it loads and that
  -- its popup has the clear background and lavender border.
  assert(pcall(require, "noice"), "noice is missing")
  assert(bg("NoiceCmdlinePopup") == nil, "noice popup is not clear")
  assert(vim.api.nvim_get_hl(0, { name = "NoiceCmdlinePopupBorder", link = false }).fg, "noice popup has no border colour")
  -- Selections share one colour that stands out on the clear background.
  for _, group in ipairs({ "Visual", "PmenuSel", "TelescopeSelection", "NeoTreeCursorLine" }) do
    assert(bg(group) == 0x525677, "Selection colour not applied: " .. group)
  end
  assert(not vim.diagnostic.config().virtual_text)
  assert(require("nvim-treesitter.configs").get_module("highlight").enable)

  local root = vim.fn.tempname() .. " project with spaces"
  io.stderr:write("neovim: project fixture\n")
  vim.fn.mkdir(root .. "/src", "p")
  vim.fn.writefile({ "fn main() {}" }, root .. "/src/main.rs")
  vim.fn.writefile({ "# Fixture", "", "Some text." }, root .. "/README.md")
  local function git(args)
    local cmd = { "git", "-C", root }
    vim.list_extend(cmd, args)
    local result = vim.system(cmd, { text = true }):wait()
    assert(result.code == 0, result.stderr)
  end
  git({ "init", "--quiet" })
  git({ "add", "." })
  git({ "-c", "user.name=Smoke", "-c", "user.email=smoke@example.test", "-c", "commit.gpgsign=false",
    "commit", "--quiet", "-m", "Fixture" })
  vim.cmd.edit(vim.fn.fnameescape(root .. "/src/main.rs"))
  -- A new tab establishes a fresh, stable project root.
  vim.cmd.tabnew(vim.fn.fnameescape(root .. "/src/main.rs"))
  assert(workspace.root() == root, "Wrong project root: " .. workspace.root())
  vim.cmd.vsplit(vim.fn.fnameescape(root .. "/README.md"))
  local main = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "# Unsaved heading" })
  vim.api.nvim_win_set_cursor(main, { 3, 2 })

  -- Neovim draws nothing on its first row, and every editor window has a
  -- header: blank alone, naming the file once the window is split.
  assert(vim.o.showtabline == 0, "A tabline runs into the tmux status bar")
  local function header(win)
    assert(vim.wo[win].winbar ~= "", "Editor window has no header row")
    return vim.api.nvim_eval_statusline(vim.wo[win].winbar, { winid = win, use_winbar = true }).str
  end
  assert(header(main):find("README.md", 1, true), "Split header does not name its file: " .. header(main))
  vim.cmd.tabnew()
  local alone = vim.api.nvim_get_current_win()
  assert(vim.trim(header(alone)) == "", "A single window's header is not blank")
  vim.cmd.tabclose()
  vim.api.nvim_set_current_win(main)

  vim.o.columns, vim.o.lines = 200, 50
  io.stderr:write("neovim: main layout with docked output\n")
  workspace.layout("main")
  settle()
  assert(workspace.label() == "Main")
  assert(not terminal.is_visible(), "Main layout docked the output before it was asked for")
  terminal.toggle_output()
  settle()
  local shell = terminal.active()
  assert(terminal.is_visible() and shell.job_id, "Shell output not docked")
  local output_buf = terminal.output_buffer()
  assert(output_buf == shell.bufnr and vim.bo[output_buf].buftype == "terminal", "Output lost native terminal rendering")
  assert(vim.bo[output_buf].readonly and not vim.bo[output_buf].modifiable, "Output is writable")
  assert(not pcall(vim.api.nvim_buf_set_lines, output_buf, 0, 0, false, { "unwanted input" }))
  assert(not shell:is_open(), "Docking the output opened an interactive shell")
  assert(shell.dir == root, "Shell is not in the project root")
  local shell_job = shell.job_id
  workspace.layout("main")
  settle()
  assert(terminal.active().job_id == shell_job, "Duplicate shells")
  assert(terminal.is_visible(), "Main layout dropped the docked output")
  assert(vim.bo[buf].modified and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "# Unsaved heading")

  io.stderr:write("neovim: hide and narrow screen\n")
  terminal.toggle_output()
  settle()
  assert(not terminal.is_visible(), "Output toggle did not hide the output")
  assert(vim.fn.jobwait({ shell_job }, 0)[1] == -1, "Hidden shell stopped")
  terminal.toggle_output()
  settle()
  vim.o.columns = 100
  workspace.apply()
  settle()
  assert(terminal.is_visible(), "Narrow screen hid the shell output")
  assert(vim.api.nvim_win_get_width(workspace.main()) >= 40, "Editor crushed on narrow screen")
  vim.o.columns = 200
  workspace.apply()
  settle()
  assert(terminal.is_visible(), "Wide screen failed to restore the layout")
  assert(not workspace.tree_window(), "Layouts opened the tree; it is a popup by default")
  assert(shell.job_id == shell_job)

  io.stderr:write("neovim: explorer popup\n")
  local function popup()
    local win = workspace.tree_window()
    return win and vim.api.nvim_get_current_win() == win and win
  end
  vim.api.nvim_set_current_win(main)
  workspace.toggle_tree()
  settle()
  assert(popup(), "Space Space did not open a focused popup")
  assert(vim.wo.winbar == "", "The file tree popup has a header row")
  assert(workspace.cursor_hidden() and vim.o.guicursor == "a:WorkspaceHiddenCursor", "Cursor shows in the tree")
  assert(vim.api.nvim_get_hl(0, { name = "WorkspaceHiddenCursor" }).blend == 100)
  assert(vim.wo.cursorline, "The tree does not mark its current row")
  -- The border carries the title on top and the key hints along the bottom.
  local function border_text()
    local text = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        vim.list_extend(text, vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false))
      end
    end
    return table.concat(text, "\n")
  end
  local edges = border_text()
  assert(edges:find("Files", 1, true) and edges:find("A folder", 1, true), "Tree popup lacks its title or hints:\n" .. edges)
  local columns = vim.o.columns
  for _, case in ipairs({ { 200, "A folder" }, { 40, " a · A · r · d · ? help " }, { 24, " ? help " } }) do
    vim.o.columns = case[1]
    local hint = workspace.tree_popup_border().text.bottom:content()
    assert(hint:find(case[2], 1, true), case[1] .. " columns got hint: " .. hint)
    assert(vim.fn.strdisplaywidth(hint) <= workspace.tree_popup_size().width - 4, "Hint overflows at " .. case[1])
  end
  vim.o.columns = columns
  assert(vim.tbl_isempty(vim.fn.maparg(" ", "n", false, true)), "The tree steals the leader key")
  vim.api.nvim_feedkeys("q", "x", false)
  settle()
  assert(not workspace.tree_window(), "q did not close the popup")
  assert(vim.api.nvim_get_current_win() == main, "Closing the popup lost the editor")
  assert(not workspace.cursor_hidden() and vim.o.guicursor ~= "a:WorkspaceHiddenCursor", "Cursor stayed hidden in the editor")
  workspace.toggle_tree()
  settle()
  assert(popup(), "Popup did not reopen")
  workspace.toggle_tree()
  settle()
  assert(not workspace.tree_window(), "Space Space did not close the popup")
  -- Opening a file from the popup closes it and shows the file in the editor.
  vim.api.nvim_set_current_win(main)
  vim.cmd.edit(vim.fn.fnameescape(root .. "/src/main.rs"))
  workspace.toggle_tree()
  assert(vim.wait(2000, function()
    return popup() and vim.api.nvim_get_current_line():find("main.rs", 1, true) ~= nil
  end, 20), "Popup did not reveal the current file")
  vim.api.nvim_win_set_cursor(0, { vim.fn.search("README", "nw"), 0 })
  vim.api.nvim_feedkeys(vim.keycode("<CR>"), "x", false)
  settle()
  assert(not workspace.tree_window(), "Opening a file left the popup open")
  assert(vim.api.nvim_get_current_win() == main, "Popup opened the file outside the editor")
  assert(vim.api.nvim_buf_get_name(0) == root .. "/README.md", "Popup opened the wrong file")
  assert(vim.bo.modified, "Popup lost unsaved edits")

  -- Folders keep their own rows, Enter toggles them, and add prompts start
  -- from the folder's editable path.
  vim.fn.mkdir(root .. "/outer/inner", "p")
  vim.fn.writefile({ "x" }, root .. "/outer/inner/leaf.txt")
  vim.api.nvim_set_current_win(main)
  workspace.toggle_tree()
  settle()
  assert(popup(), "Tree popup did not open")
  -- Rows end in padding and a Git mark, so match the name as a whole word.
  local function row(name) return vim.fn.search("\\V\\<" .. name .. "\\>", "w") end
  local function shows(name) return vim.fn.search("\\V\\<" .. name .. "\\>", "nw") > 0 end
  assert(row("outer") > 0, "outer is missing:\n" .. table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
  assert(not shows("outer/inner"), "Folders were merged into one row")
  vim.api.nvim_feedkeys(vim.keycode("<CR>"), "x", false)
  settle()
  assert(shows("inner"), "Enter did not expand the folder")
  row("outer")
  vim.api.nvim_feedkeys(vim.keycode("<CR>"), "x", false)
  settle()
  assert(not shows("inner"), "Enter did not collapse the open folder")
  vim.api.nvim_feedkeys(vim.keycode("<CR>"), "x", false)
  settle()
  row("inner")
  local input, offered = vim.ui.input, nil
  vim.ui.input = function(opts, done) offered = opts.default; done(nil) end
  vim.api.nvim_feedkeys("a", "x", false)
  settle()
  vim.ui.input = input
  assert(offered == "outer/inner/", "Add did not offer the editable folder path: " .. tostring(offered))
  vim.api.nvim_feedkeys("q", "x", false)
  settle()
  vim.fn.delete(root .. "/outer", "rf")
  vim.api.nvim_set_current_win(main)

  -- Narrow windows get the same popup; the tree never docks as a split.
  vim.o.columns = 90
  workspace.apply()
  settle()
  local splits = #vim.api.nvim_tabpage_list_wins(0)
  workspace.toggle_tree()
  settle()
  assert(popup(), "Narrow screen did not open the popup")
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "x", false)
  settle()
  assert(not workspace.tree_window(), "Esc did not close the popup")
  assert(#vim.api.nvim_tabpage_list_wins(0) == splits, "The tree left a window behind")
  vim.o.columns = 200
  workspace.apply()
  settle()
  assert(not workspace.tree_window(), "Wide screen docked a tree")
  vim.api.nvim_set_current_win(main)

  io.stderr:write("neovim: shared shell popup\n")
  vim.api.nvim_set_current_win(main)
  local before_popup = vim.fn.winlayout()
  terminal.toggle()
  settle()
  local popup = vim.api.nvim_get_current_win()
  assert(shell.window == popup and vim.api.nvim_win_get_config(popup).relative == "editor")
  assert(terminal.is_visible(), "Popup hid the read-only output")
  assert(terminal.active().job_id == shell_job, "Popup created another shell")
  vim.api.nvim_chan_send(shell_job, "printf 'shared-shell-output\\n'\n")
  assert(vim.wait(3000, function()
    return vim.tbl_contains(vim.api.nvim_buf_get_lines(output_buf, 0, -1, false), "shared-shell-output")
  end, 20), "Bottom output did not update from popup shell")
  local escape = vim.fn.maparg("<Esc><Esc>", "t", false, true)
  assert(type(escape.callback) == "function", "Popup has no close mapping")
  escape.callback()
  settle()
  assert(not shell:is_open() and vim.api.nvim_get_current_win() == main, "Escape failed to return to editor")
  assert(vim.deep_equal(before_popup, vim.fn.winlayout()), "Popup changed editor topology")
  terminal.toggle()
  settle()
  assert(terminal.active().job_id == shell_job, "Reopening replaced the shell")
  terminal.close_popup()
  settle()

  -- Review leaves the origin's editor windows and modified buffers intact.
  io.stderr:write("neovim: Git review\n")
  workspace.layout("main")
  settle()
  local origin = vim.api.nvim_get_current_tabpage()
  local origin_layout = vim.fn.winlayout()
  workspace.layout("review")
  settle()
  local review = vim.api.nvim_get_current_tabpage()
  assert(review ~= origin and workspace.label() == "Review", "Review did not open its own tab")
  workspace.layout("review")
  settle()
  assert(vim.api.nvim_get_current_tabpage() == review, "Review duplicated its tab")
  workspace.layout("main")
  settle()
  assert(vim.api.nvim_get_current_tabpage() == origin, "Main layout did not leave the review")
  assert(workspace.label() == "Main")
  assert(vim.deep_equal(vim.fn.winlayout(), origin_layout), "Review damaged original workspace")
  assert(vim.bo[buf].modified, "Review lost unsaved edits")

  io.stderr:write("neovim: Cargo tasks\n")
  vim.fn.writefile({ '[package]', 'name = "workspace-smoke"', 'version = "0.1.0"', 'edition = "2021"' }, root .. "/Cargo.toml")
  assert(terminal.cargo("check"), "Cargo check did not start")
  local task = terminal.task()
  assert(task.running and terminal.active().job_id == shell_job, "Cargo created another shell")
  assert(not terminal.cargo("test"), "Busy task accepted a second command")
  assert(vim.wait(10000, function() return not task.running end, 20), "Cargo check timed out")
  assert(task.exit_code == 0, "Cargo check failed")
  assert(vim.wait(2000, function()
    return table.concat(vim.api.nvim_buf_get_lines(output_buf, 0, -1, false), "\n"):find("Finished", 1, true) ~= nil
  end, 20), "Task output was not mirrored")
  workspace.layout("main")
  settle()
  assert(terminal.active().job_id == shell_job and terminal.output_buffer() == output_buf, "Layout lost shell/output")

  -- Format real fixtures using Nix-provided executables.
  io.stderr:write("neovim: formatters\n")
  vim.cmd.enew()
  vim.bo.filetype = "nix"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "{foo=1;bar=[1 2];}" })
  require("conform").format({ async = false, timeout_ms = 5000, lsp_format = "never" })
  assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"):find("foo = 1;", 1, true))
  vim.cmd.enew()
  vim.bo.filetype = "rust"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'fn main(){println!("hi");}' })
  require("conform").format({ async = false, timeout_ms = 5000, lsp_format = "never" })
  assert(#vim.api.nvim_buf_get_lines(0, 0, -1, false) > 1, "Rust formatter failed")
  -- A real language-server diagnostic; this malformed expression needs no
  -- external Nix inputs or network access.
  vim.fn.writefile({ "{ broken = ; }" }, root .. "/broken.nix")
  vim.cmd.edit(vim.fn.fnameescape(root .. "/broken.nix"))
  local nix_buf = vim.api.nvim_get_current_buf()
  assert(vim.wait(15000, function() return #vim.diagnostic.get(nix_buf) > 0 end, 20), "nixd produced no diagnostics")
  assert(#vim.lsp.get_clients({ bufnr = nix_buf, name = "nixd" }) == 1, "nixd did not attach")

  -- Markdown renders in the buffer, and the toggle switches it off.
  io.stderr:write("neovim: rendered markdown\n")
  local doc = vim.fn.tempname() .. ".md"
  vim.fn.writefile({ "# Heading", "", "- [ ] open task", "- [x] done task", "", "| a | b |", "| - | - |", "| 1 | 2 |" }, doc)
  vim.cmd.edit(vim.fn.fnameescape(doc))
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  local function decorations()
    local ns = vim.api.nvim_get_namespaces()["render-markdown.nvim"]
    return ns and #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) or 0
  end
  assert(vim.wait(3000, function() return decorations() > 0 end, 20), "Markdown was not rendered")
  -- Updates within the plugin's 100 ms debounce of a render are dropped.
  settle()
  vim.cmd("RenderMarkdown toggle")
  assert(vim.wait(3000, function() return decorations() == 0 end, 20), "Space um did not switch rendering off")
  vim.cmd("RenderMarkdown toggle")
  vim.cmd("bwipeout!")

  -- Today's journal through the zk language server, from the shared template.
  io.stderr:write("neovim: zk journal\n")
  local notebook = vim.fn.tempname() .. " notes"
  vim.fn.mkdir(notebook .. "/.zk", "p")
  vim.fn.mkdir(notebook .. "/journal", "p")
  vim.env.ZK_NOTEBOOK_DIR = notebook
  local entry = notebook .. "/journal/" .. os.date("%Y-%m-%d") .. ".md"
  require("notes").today()
  assert(vim.wait(15000, function() return vim.api.nvim_buf_get_name(0) == entry end, 50),
    "Space nd did not open today's journal: " .. vim.api.nvim_buf_get_name(0))
  local journal = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  assert(journal:find("## Focus", 1, true) and journal:find("tags: [journal]", 1, true), "Journal ignored daily.md:\n" .. journal)
  require("notes").today()
  vim.wait(1000, function() return false end, 50)
  assert(vim.api.nvim_buf_get_name(0) == entry, "A second Space nd did not reopen the entry")
  assert(#vim.fn.readdir(notebook .. "/journal") == 1, "A second Space nd created another entry")
  -- The todo list is one file from todo.md, and the checkbox toggle cycles.
  local notes = require("notes")
  notes.todo()
  assert(vim.wait(15000, function() return vim.api.nvim_buf_get_name(0) == notebook .. "/todo.md" end, 50),
    "Space nx did not open todo.md: " .. vim.api.nvim_buf_get_name(0))
  assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"):find("## Someday", 1, true), "Todo ignored todo.md")
  vim.cmd.enew()
  for _, case in ipairs({ { "buy milk", "- [ ] buy milk" }, { "- [ ] buy milk", "- [x] buy milk" },
    { "- [x] buy milk", "- [ ] buy milk" }, { "  * call Sam", "  * [ ] call Sam" } }) do
    vim.api.nvim_set_current_line(case[1])
    notes.toggle_task()
    assert(vim.api.nvim_get_current_line() == case[2], case[1] .. " -> " .. vim.api.nvim_get_current_line())
  end
  for _, case in ipairs({ { "- [ ] call Sam", true }, { "  * [ ] nested", true }, { "- [ ] ", false },
    { "- [x] done", false } }) do
    local found = vim.fn.system({ "rg", "--quiet", notes.task_pattern }, case[1] .. "\n")
    assert((vim.v.shell_error == 0) == case[2], "Task pattern wrong for: " .. case[1])
  end
  vim.cmd("bwipeout!")

  -- Re-editing any Markdown buffer runs the stock ftplugin's undo, whose
  -- `silent! nunmap <buffer> gO` still records E31. Nothing else may fail.
  assert(vim.v.errmsg == "" or vim.v.errmsg == "E31: No such mapping", vim.v.errmsg)
  vim.v.errmsg = ""

  -- A non-repository workspace must still support the tree and terminals.
  local plain = vim.fn.tempname() .. " plain directory"
  vim.fn.mkdir(plain, "p")
  vim.cmd.tabnew(vim.fn.fnameescape(plain .. "/new.txt"))
  assert(workspace.root() == plain)
  assert(terminal.active().job_id == shell_job, "Another project created a second shell")
  workspace.layout("main")
  settle()
  local tab = vim.api.nvim_get_current_tabpage()
  workspace.layout("review")
  assert(vim.api.nvim_get_current_tabpage() == tab, "Non-Git review created a tab")
  assert(vim.v.errmsg == "", vim.v.errmsg)
end

local ok, err = xpcall(check, debug.traceback)
if not ok then io.stderr:write(err .. "\n"); vim.cmd("cquit 1") end
vim.cmd("qa!")
