-- Behavioral checks against the actual generated Nixvim package.
local function settle()
  vim.wait(180, function() return false end, 10)
end
local function check()
  io.stderr:write("neovim: startup\n")
  assert(vim.v.errmsg == "", vim.v.errmsg)
  local workspace = require("workspace")
  local terminal = require("workspace.terminal")
  local ai = require("workspace.ai")
  local function mapping(key, mode)
    return vim.fn.maparg(key:gsub("<leader>", " "), mode or "n", false, true)
  end
  for _, command in ipairs({ "Telescope", "Neotree", "ToggleTerm", "DiffviewOpen",
    "Trouble", "Sidekick", "WorkspaceLayout", "WorkspaceRestore" }) do
    assert(vim.fn.exists(":" .. command) == 2, "Missing command: " .. command)
  end
  for _, key in ipairs({ "<leader>e", "<leader>E", "<leader>z", "<leader>l1", "<leader>l4",
    "<leader>tt", "<leader>to", "<leader>aa", "<leader>af", "<leader>cf", "<leader>rr" }) do
    assert(not vim.tbl_isempty(mapping(key)), "Missing mapping: " .. key)
  end
  assert(not vim.tbl_isempty(mapping("<leader>av", "x")))
  assert(mapping("<Tab>").rhs == "<cmd>bnext<CR>")
  assert(mapping("<S-Tab>").rhs == "<cmd>bprevious<CR>")
  assert(vim.tbl_isempty(mapping("<leader>q")))
  assert(vim.tbl_isempty(mapping("<leader>rn")))
  assert(vim.tbl_isempty(mapping("<leader>tn")))
  assert(vim.tbl_isempty(mapping("<leader>ts")))
  -- Action prefixes must not delay longer mappings in the same namespace.
  for _, prefix in ipairs({ "f", "g", "l", "t", "a", "c", "b", "w", "r", "x" }) do
    assert(vim.tbl_isempty(mapping("<leader>" .. prefix)), "Executable prefix: " .. prefix)
  end
  assert(vim.o.termguicolors and vim.o.undofile)
  assert(not vim.diagnostic.config().virtual_text)
  assert(require("nvim-treesitter.configs").get_module("highlight").enable)
  assert(not require("sidekick.config").nes.enabled)
  assert(not require("sidekick.config").cli.mux.enabled)
  assert(vim.deep_equal(require("sidekick.config").cli.tools.codex.cmd, { "codex" }))

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

  -- Replace Codex with an input recorder before any sessions are initialized.
  local input = root .. "/ai-input"
  require("sidekick.config").cli.tools.codex = {
    cmd = { "bash", "--noprofile", "--norc", "-c",
      'printf "Agent fixture\\nContext recorder\\nNo network\\nProject session\\nDocked tool\\nReady\\n>\\n"; while IFS= read -r line; do printf "%s\\n" "$line" >> "$CODEX_TEST_INPUT"; done' },
    env = { CODEX_TEST_INPUT = input },
  }
  vim.o.columns, vim.o.lines = 200, 50
  io.stderr:write("neovim: full layout\n")
  workspace.layout("full")
  settle()
  local shell, agent = terminal.active(), ai.get()
  assert(terminal.is_visible() and shell.job_id, "Shell output not docked")
  assert(agent and agent:is_open() and agent:is_running(), "AI not docked")
  local output_buf = terminal.output_buffer()
  assert(output_buf == shell.bufnr and vim.bo[output_buf].buftype == "terminal", "Output lost native terminal rendering")
  assert(vim.bo[output_buf].readonly and not vim.bo[output_buf].modifiable, "Output is writable")
  assert(not pcall(vim.api.nvim_buf_set_lines, output_buf, 0, 0, false, { "unwanted input" }))
  assert(not shell:is_open(), "Full opened an interactive shell")
  assert(vim.api.nvim_win_get_config(agent.win).relative == "", "AI floated")
  assert(agent.cwd == root and shell.dir == root, "Tools disagree on project root")
  assert(agent.opts.layout == "right")
  local shell_job, ai_job = shell.job_id, agent.job
  vim.api.nvim_set_current_win(agent.win)
  workspace.resize("width", 4)
  settle()
  assert(workspace.state().sizes.right == 54, "Panel resize was not remembered")
  workspace.layout("full")
  settle()
  assert(terminal.active().job_id == shell_job and ai.get().job == ai_job, "Duplicate processes")
  assert(vim.api.nvim_win_get_width(agent.win) == 54, "Panel resize was lost")

  vim.api.nvim_set_current_win(main)
  io.stderr:write("neovim: focus round-trip\n")
  local layout = vim.fn.winlayout()
  local view = vim.fn.winsaveview()
  workspace.focus()
  settle()
  assert(workspace.label() == "Focus")
  assert(Snacks.zen.win:valid())
  assert(vim.o.laststatus == 0 and vim.o.showtabline == 0, "Focus chrome visible")
  workspace.restore()
  settle()
  assert(vim.deep_equal(vim.fn.winlayout(), layout), "Focus changed split topology")
  assert(vim.deep_equal(vim.fn.winsaveview(), view), "Focus lost cursor/view")
  assert(vim.bo[buf].modified and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "# Unsaved heading")
  assert(shell.job_id == shell_job and agent.job == ai_job, "Focus restarted jobs")

  workspace.layout("code")
  io.stderr:write("neovim: hide and narrow screen\n")
  settle()
  assert(not terminal.is_visible() and not agent:is_open(), "Code failed to hide tools")
  assert(vim.fn.jobwait({ shell_job, ai_job }, 0)[1] == -1, "Hidden shell stopped")
  assert(agent:is_running(), "Hidden AI stopped")
  workspace.layout("full")
  settle()
  vim.o.columns = 100
  workspace.apply()
  settle()
  assert(workspace.geometry().ai_dock == "bottom")
  assert(not terminal.is_visible() and agent:is_open(), "Narrow bottom slot is not shared")
  assert(agent.opts.layout == "bottom")
  assert(vim.api.nvim_win_get_config(agent.win).relative == "", "Narrow AI floated")
  assert(vim.api.nvim_win_get_width(workspace.main()) >= 40, "Editor crushed on narrow screen")
  terminal.toggle_output()
  settle()
  assert(terminal.is_visible() and not agent:is_open(), "Output did not select bottom slot")
  vim.o.columns = 200
  workspace.apply()
  settle()
  assert(terminal.is_visible() and agent:is_open(), "Wide screen failed to restore tools")
  assert(shell.job_id == shell_job and agent.job == ai_job)

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

  vim.api.nvim_set_current_win(main)
  ai.send("file")
  io.stderr:write("neovim: AI context\n")
  assert(vim.wait(6500, function()
    return vim.fn.filereadable(input) == 1 and table.concat(vim.fn.readfile(input), "\n"):find("README.md", 1, true)
  end, 20), "AI received no file context: " .. (vim.fn.filereadable(input) == 1 and table.concat(vim.fn.readfile(input), "\n") or "missing recorder output"))
  local received = table.concat(vim.fn.readfile(input), "\n")
  assert(received:find("README.md", 1, true), "AI received wrong file context: " .. received)
  vim.api.nvim_set_current_win(main)
  vim.fn.delete(input)
  vim.api.nvim_win_set_cursor(main, { 3, 0 })
  vim.cmd("normal! V")
  ai.send("selection")
  assert(vim.wait(6500, function()
    return vim.fn.filereadable(input) == 1 and table.concat(vim.fn.readfile(input), "\n"):find("Some text.", 1, true)
  end, 20), "AI received no selection")
  assert(table.concat(vim.fn.readfile(input), "\n"):find("Some text.", 1, true))

  -- Review leaves the origin's editor windows and modified buffers intact.
  io.stderr:write("neovim: Git review\n")
  workspace.layout("code")
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
  workspace.restore()
  settle()
  assert(vim.api.nvim_get_current_tabpage() == origin)
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
  workspace.layout("code")
  workspace.layout("full")
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

  -- A non-repository workspace must still support the tree and terminals.
  local plain = vim.fn.tempname() .. " plain directory"
  vim.fn.mkdir(plain, "p")
  vim.cmd.tabnew(vim.fn.fnameescape(plain .. "/new.txt"))
  assert(workspace.root() == plain)
  assert(terminal.active().job_id == shell_job, "Another project created a second shell")
  workspace.layout("code")
  settle()
  local tab = vim.api.nvim_get_current_tabpage()
  workspace.layout("review")
  assert(vim.api.nvim_get_current_tabpage() == tab, "Non-Git review created a tab")
  ai.hide()
  assert(vim.v.errmsg == "", vim.v.errmsg)
end

local ok, err = xpcall(check, debug.traceback)
if not ok then io.stderr:write(err .. "\n"); vim.cmd("cquit 1") end
vim.cmd("qa!")
