-- Behavioral checks against the actual generated Nixvim package.
local function settle()
  vim.wait(180, function() return false end, 10)
end
local function check()
  io.stderr:write("neovim: startup\n")
  assert(vim.v.errmsg == "", vim.v.errmsg)
  local workspace = require("workspace")
  local terminal = require("workspace.terminal")
  local task = require("workspace.task")
  local rust = require("workspace.rust")
  local function mapping(key, mode)
    return vim.fn.maparg(key:gsub("<leader>", " "), mode or "n", false, true)
  end
  for _, command in ipairs({ "Telescope", "Neotree", "ToggleTerm", "DiffviewOpen",
    "Trouble", "WorkspaceLayout", "WorkspaceRestore", "Oil", "DapContinue", "DapViewToggle", "ZkNew", "ZkNotes", "ZkBacklinks", "RenderMarkdown" }) do
    assert(vim.fn.exists(":" .. command) == 2, "Missing command: " .. command)
  end
  for _, key in ipairs({ "<leader>ff", "<leader>fg", "<leader>l1", "<leader>l2",
    "<leader>tt", "<leader>to", "<leader>cf", "<leader>rr", "<leader>rt", "<leader>rT", "<leader>rc",
    "<leader>rl", "<leader>rs", "<leader>rx", "<leader>ri", "<leader>rd", "<leader>db", "<leader>dc", "<leader>du",
    "<leader>uh", "<C-/>", "<C-_>", "-", "<leader>-",
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
  assert(not vim.tbl_isempty(mapping("<C-/>", "i")), "The shell toggle is missing in Insert mode")
  for _, prefix in ipairs({ "f", "g", "l", "t", "c", "b", "w", "r", "d", "x", "n", "u" }) do
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
  io.stderr:write("neovim: main layout\n")
  workspace.layout("main")
  settle()
  assert(workspace.label() == "Main")
  assert(not task.is_visible(), "Main layout docked a pane before anything ran")
  assert(not workspace.tree_window(), "Layouts opened the tree; it is a popup by default")
  assert(vim.bo[buf].modified and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "# Unsaved heading")

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

  -- One key opens the shell ready for typing and puts the editor back as it was.
  io.stderr:write("neovim: shell toggle\n")
  vim.api.nvim_set_current_win(main)
  local before_popup = vim.fn.winlayout()
  local cursor = vim.api.nvim_win_get_cursor(main)
  terminal.toggle()
  settle()
  local shell = terminal.active()
  local shell_job = shell.job_id
  local shell_win = vim.api.nvim_get_current_win()
  assert(shell.window == shell_win and vim.api.nvim_win_get_config(shell_win).relative == "editor", "Shell is not a popup")
  assert(vim.bo[shell.bufnr].buftype == "terminal" and shell.dir == root, "Shell is not a terminal in the project root")
  vim.api.nvim_chan_send(shell_job, "printf 'shell-%s\\n' output\n")
  assert(vim.wait(5000, function()
    return table.concat(vim.api.nvim_buf_get_lines(shell.bufnr, 0, -1, false), "\n"):find("shell-output", 1, true) ~= nil
  end, 20), "Shell did not run a command")
  for _, key in ipairs(terminal.toggle_keys) do
    assert(type(vim.fn.maparg(key, "t", false, true).callback) == "function", "Shell cannot be left with " .. key)
  end
  vim.fn.maparg("<C-/>", "t", false, true).callback()
  settle()
  assert(not terminal.popup_open() and vim.api.nvim_get_current_win() == main, "Toggle failed to return to the editor")
  assert(vim.deep_equal(cursor, vim.api.nvim_win_get_cursor(main)), "Returning moved the cursor")
  assert(vim.deep_equal(before_popup, vim.fn.winlayout()), "Shell changed editor topology")
  terminal.toggle()
  settle()
  assert(terminal.active().job_id == shell_job, "Reopening replaced the shell")
  terminal.close_popup()
  settle()
  assert(vim.bo[buf].modified, "Shell lost unsaved edits")

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

  -- Tasks run in their own pane and leave focus, mode, and the shell alone.
  io.stderr:write("neovim: tasks\n")
  vim.fn.writefile({ '[package]', 'name = "workspace-smoke"', 'version = "0.1.0"', 'edition = "2021"' }, root .. "/Cargo.toml")
  vim.api.nvim_set_current_win(main)
  local function finished(timeout)
    local current = task.task()
    assert(vim.wait(timeout or 60000, function() return not current.running and current.elapsed ~= nil end, 20),
      current.name .. " timed out")
    settle()
    return current
  end
  local function output()
    return table.concat(vim.api.nvim_buf_get_lines(task.task().buf, 0, -1, false), "\n")
  end
  assert(task.run({ name = "echo", cmd = { "sh", "-c", "echo task-ran; exit 3" }, cwd = root }), "Task did not start")
  assert(vim.api.nvim_get_current_win() == main, "Running a task took focus")
  assert(not vim.bo[buf].modified, "Running a task did not save the open buffers")
  local done = finished()
  assert(done.exit_code == 3 and output():find("task-ran", 1, true), "Task output or exit code lost: " .. output())
  assert(task.is_visible(), "A failed task did not show its output")
  assert(task.status() == "✗ echo", "Statusline shows: " .. task.status())
  assert(vim.api.nvim_get_current_win() == main, "A finished task took focus")
  -- A quiet task that succeeds quickly never opens the pane, and closes one it opened.
  task.toggle()
  settle()
  assert(not task.is_visible(), "Space to did not hide the output")
  assert(task.run({ name = "quiet", cmd = { "true" }, cwd = root, quiet = true }))
  done = finished()
  assert(done.exit_code == 0 and not task.is_visible(), "A quick quiet task opened the pane")
  task.quiet_delay = 50
  assert(task.run({ name = "slow", cmd = { "sh", "-c", "sleep 0.4" }, cwd = root, quiet = true }))
  assert(vim.wait(2000, task.is_visible, 10), "A slow quiet task never showed its output")
  done = finished()
  assert(not task.is_visible(), "A quiet task left its pane open after succeeding")
  task.quiet_delay = 800
  -- Rerun restarts a task that is still going; stop ends it.
  assert(task.run({ name = "server", cmd = { "sh", "-c", "echo up; sleep 60" }, cwd = root }))
  local first = task.task()
  assert(task.rerun() and task.task() ~= first and task.task().name == "server", "Rerun did not restart the task")
  assert(vim.wait(5000, function() return not first.running end, 20), "Rerun left the old task running")
  assert(#vim.tbl_filter(function(win)
    return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "workspace_task"
  end, vim.api.nvim_tabpage_list_wins(0)) == 1, "Rerun opened a second pane")
  -- The pane takes input when asked, and the toggle key leaves it.
  task.focus()
  settle()
  assert(vim.api.nvim_get_current_buf() == task.task().buf, "Space ri did not enter the task")
  vim.fn.maparg("<C-/>", "t", false, true).callback()
  settle()
  assert(vim.api.nvim_get_current_win() == main, "Toggle did not leave the task pane")
  task.stop()
  done = finished()
  assert(done.stopped and task.status() == "■ server", "Stop did not end the task: " .. task.status())
  assert(terminal.active().job_id == shell_job, "Tasks replaced the shell")

  io.stderr:write("neovim: Cargo\n")
  vim.cmd.edit(vim.fn.fnameescape(root .. "/src/main.rs"))
  -- A pane that was already open stays open; one the task opened goes away again.
  task.toggle()
  settle()
  assert(not task.is_visible())
  assert(rust.cargo({ "check" }, { quiet = true }), "Cargo check did not start")
  done = finished(120000)
  assert(done.exit_code == 0, "Cargo check failed:\n" .. output())
  assert(output():find("Finished", 1, true), "Cargo output was not captured:\n" .. output())
  assert(not task.is_visible(), "A clean check left its pane open")
  -- Compiler errors become quickfix entries at the right file.
  vim.fn.writefile({ "fn main() {", "    let unused = 1;", "    let x: u32 = \"text\";", "}" }, root .. "/src/main.rs")
  vim.cmd("edit!")
  assert(rust.cargo({ "check" }, { quiet = true }))
  done = finished(120000)
  assert(done.exit_code ~= 0 and task.is_visible(), "A failed check did not show its output")
  local qf = vim.fn.getqflist({ items = 1, title = 1 })
  local errors = vim.tbl_filter(function(item) return item.type == "E" end, qf.items)
  assert(#errors == 1, "Expected one compiler error in quickfix:\n" .. vim.inspect(qf.items) .. output())
  assert(vim.api.nvim_buf_get_name(errors[1].bufnr) == root .. "/src/main.rs" and errors[1].lnum == 3,
    "Quickfix points at the wrong place: " .. vim.inspect(errors[1]))
  assert(errors[1].text:find("mismatched types", 1, true), "Quickfix lost the message: " .. errors[1].text)
  -- A clean run clears the list it made.
  vim.fn.writefile({ "fn main() {}" }, root .. "/src/main.rs")
  vim.cmd("edit!")
  assert(task.rerun())
  done = finished(120000)
  assert(done.exit_code == 0 and #vim.fn.getqflist() == 0, "A clean check left stale errors in quickfix")
  -- Panics from a run or a test are locations too.
  local items = rust.parse({ "thread 'main' panicked at src/main.rs:1:13:", "boom", "note: run with `RUST_BACKTRACE=1`",
    "warning: unused variable: `x`", " --> src/main.rs:1:5" }, { cwd = root })
  assert(#items == 2 and items[1].text == "boom" and items[1].lnum == 1 and items[2].type == "W",
    "Panic parsing is wrong: " .. vim.inspect(items))

  -- rust-analyzer attaches through rustaceanvim, once, and finds what is runnable.
  io.stderr:write("neovim: rust-analyzer\n")
  vim.fn.writefile({ "fn main() {", "    println!(\"hi\");", "}", "", "#[cfg(test)]", "mod tests {", "    #[test]",
    "    fn passes() {", "        assert_eq!(1 + 1, 2);", "    }", "}" }, root .. "/src/main.rs")
  vim.cmd("edit!")
  local rust_buf = vim.api.nvim_get_current_buf()
  assert(vim.fn.exists(":RustLsp") == 2, "rustaceanvim did not load for a Rust buffer")
  assert(vim.wait(30000, function() return #vim.lsp.get_clients({ bufnr = rust_buf, name = "rust-analyzer" }) == 1 end, 50),
    "rust-analyzer did not attach exactly once")
  local function runnable_at(line, expect)
    vim.api.nvim_win_set_cursor(0, { line, 4 })
    local name
    assert(vim.wait(120000, function()
      local started = line == 9 and rust.test() or line ~= 9 and rust.run()
      vim.wait(1500, function() return task.task().name:find(expect, 1, true) ~= nil end, 20)
      name = task.task().name
      return started and name:find(expect, 1, true) ~= nil
    end, 500), "No runnable matching " .. expect .. " at line " .. line .. "; last task: " .. tostring(name))
    return finished(120000)
  end
  done = runnable_at(2, "run workspace-smoke")
  assert(done.exit_code == 0 and output():find("hi", 1, true), "Space rr did not run the binary:\n" .. output())
  assert(task.is_visible(), "A run's output did not stay open")
  done = runnable_at(9, "passes")
  assert(done.exit_code == 0 and output():find("1 passed", 1, true), "Space rt did not run the test:\n" .. output())
  vim.api.nvim_set_current_win(main)
  workspace.layout("main")
  settle()

  -- The same keys drive TypeScript, with the tools the project and Node provide.
  io.stderr:write("neovim: TypeScript\n")
  local ts, lang = require("workspace.ts"), require("workspace.lang")
  local web = root .. "/web"
  vim.fn.mkdir(web .. "/src", "p")
  vim.fn.mkdir(web .. "/test", "p")
  vim.fn.writefile({ '{ "name": "web", "type": "module", "scripts": { "hello": "echo script-ran" } }' }, web .. "/package.json")
  vim.fn.writefile({ '{ "compilerOptions": { "strict": true, "module": "nodenext", "target": "es2022", "types": [] },',
    '  "include": ["src"] }' }, web .. "/tsconfig.json")
  vim.fn.writefile({ "const total: number = 2 + 3;", "console.log(`total = ${total}`);" }, web .. "/src/app.ts")
  vim.fn.writefile({ 'import { test } from "node:test";', 'import assert from "node:assert";', "",
    'test("adds (1)", () => {', "  assert.equal(1 + 1, 2);", "});", "",
    'test("breaks", () => {', "  assert.equal(1, 2);", "});" }, web .. "/test/app.test.ts")
  vim.cmd.edit(vim.fn.fnameescape(web .. "/src/app.ts"))
  local ts_buf = vim.api.nvim_get_current_buf()
  assert(ts.root() == web, "Wrong package root: " .. tostring(ts.root()))
  assert(lang.run(), "Space rr did not start in a TypeScript file")
  done = finished()
  assert(done.name == "run app.ts" and done.exit_code == 0 and output():find("total = 5", 1, true),
    "Space rr did not run the file:\n" .. output())
  -- Only the test under the cursor runs; its name is passed literally.
  vim.cmd.edit(vim.fn.fnameescape(web .. "/test/app.test.ts"))
  vim.api.nvim_win_set_cursor(0, { 5, 2 })
  assert(lang.test(), "Space rt did not start")
  done = finished()
  assert(done.name == "test adds (1)" and done.exit_code == 0, "Space rt ran the wrong test: " .. done.name .. "\n" .. output())
  -- A failing test opens the pane and points quickfix at the assertion.
  vim.api.nvim_win_set_cursor(0, { 9, 2 })
  assert(lang.run(), "Space rr did not run the test under the cursor")
  done = finished()
  assert(done.name == "test breaks" and done.exit_code ~= 0 and task.is_visible(), "A failing test did not show:\n" .. output())
  qf = vim.fn.getqflist()
  assert(#qf >= 1 and vim.api.nvim_buf_get_name(qf[1].bufnr) == web .. "/test/app.test.ts" and qf[1].lnum == 9,
    "Quickfix missed the failing assertion: " .. vim.inspect(qf) .. output())
  -- The type checker's errors become quickfix entries.
  vim.fn.writefile({ "const total: number = 2 + 3;", 'const bad: number = "text";', "console.log(total, bad);" }, web .. "/src/app.ts")
  vim.api.nvim_set_current_buf(ts_buf)
  vim.cmd("edit!")
  assert(lang.check(), "Space rc did not start")
  done = finished(120000)
  qf = vim.fn.getqflist()
  assert(done.name == "tsc" and done.exit_code ~= 0 and #qf == 1, "Type errors missing from quickfix:\n" .. output())
  assert(vim.api.nvim_buf_get_name(qf[1].bufnr) == web .. "/src/app.ts" and qf[1].lnum == 2 and qf[1].text:find("TS2322", 1, true),
    "Quickfix points at the wrong place: " .. vim.inspect(qf[1]))
  -- The language server reports the same error in the buffer.
  assert(vim.wait(60000, function() return #vim.diagnostic.get(ts_buf) > 0 end, 50), "vtsls produced no diagnostics")
  assert(#vim.lsp.get_clients({ bufnr = ts_buf, name = "vtsls" }) == 1, "vtsls did not attach")
  -- Lint findings and stack frames in other tools' formats.
  items = ts.parse({ web .. "/src/app.ts", "  2:7  error  'bad' is never used  no-unused-vars", "",
    " ❯ test/app.test.ts:9:10", "    at run (node:internal/test_runner/test:1:1)",
    "    at thing (" .. web .. "/node_modules/x/index.js:1:1)" }, { cwd = web })
  assert(#items == 2 and items[1].lnum == 2 and items[1].type == "E" and items[2].lnum == 9,
    "Lint or stack parsing is wrong: " .. vim.inspect(items))
  assert(vim.deep_equal(ts.formatters(ts_buf), { "prettier" }), "Prettier is not the default formatter")
  vim.fn.writefile({ "{}" }, web .. "/biome.json")
  vim.fn.mkdir(web .. "/node_modules/.bin", "p")
  vim.fn.writefile({ "#!/bin/sh" }, web .. "/node_modules/.bin/biome")
  assert(vim.deep_equal(ts.formatters(ts_buf), { "biome" }), "A Biome project is not formatted with Biome")
  vim.fn.delete(web .. "/biome.json")
  vim.fn.delete(web .. "/node_modules", "rf")
  -- A package script, picked once.
  local select = vim.ui.select
  vim.ui.select = function(choices, _, on_choice) on_choice(choices[1]) end
  assert(ts.script(), "Space rs did not offer the scripts")
  vim.ui.select = select
  done = finished()
  assert(done.name == "npm run hello" and done.exit_code == 0 and output():find("script-ran", 1, true),
    "Space rs did not run the script:\n" .. output())
  -- Outside a source file, the nearest project file picks the language.
  vim.cmd.edit(vim.fn.fnameescape(web .. "/tsconfig.json"))
  assert(lang.check() and task.task().name == "tsc", "package.json did not select TypeScript")
  finished(120000)
  vim.cmd.edit(vim.fn.fnameescape(root .. "/Cargo.toml"))
  assert(lang.check() and task.task().name == "cargo clippy", "Cargo.toml did not select Rust")
  task.stop()
  finished()
  vim.fn.writefile({ "const total: number = 2 + 3;", "console.log(total);" }, web .. "/src/app.ts")
  vim.api.nvim_set_current_win(main)
  workspace.layout("main")
  settle()

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
  vim.cmd.enew()
  vim.bo.filetype = "go"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "package main", "func main(){println(1)}" })
  require("conform").format({ async = false, timeout_ms = 5000, lsp_format = "never" })
  assert(vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] == "", "Go formatter failed")
  vim.fn.writefile({ "module example.com/smoke", "", "go 1.21" }, root .. "/go.mod")
  vim.fn.writefile({ "package main", "func main() { unknown() }" }, root .. "/main.go")
  vim.cmd.edit(vim.fn.fnameescape(root .. "/main.go"))
  local go_buf = vim.api.nvim_get_current_buf()
  assert(vim.wait(15000, function() return #vim.diagnostic.get(go_buf) > 0 end, 20), "gopls produced no diagnostics")
  assert(#vim.lsp.get_clients({ bufnr = go_buf, name = "gopls" }) == 1, "gopls did not attach")
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
  assert(not task.is_visible(), "A new tab inherited the task pane")
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
