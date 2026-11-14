-- Neovim commands for the zk notebook. Every command targets the notebook in
-- $ZK_NOTEBOOK_DIR, whichever project Neovim was opened in.
local M = {}

local function root()
  return vim.env.ZK_NOTEBOOK_DIR or vim.fs.normalize("~/notes")
end

local function opts(extra)
  return vim.tbl_extend("force", { notebook_path = root() }, extra or {})
end

local function ask(prompt, callback)
  vim.ui.input({ prompt = prompt }, function(text)
    text = text and vim.trim(text) or ""
    if text ~= "" then callback(text) end
  end)
end

local prompts = { meetings = "Meeting title: ", projects = "Project name: ", prompts = "Prompt name: " }

-- A new note from the note template, or from a group's template in its folder:
-- meetings/, projects/, or prompts/.
function M.new(dir)
  ask(prompts[dir] or "Note title: ", function(title)
    require("zk").new(opts({ title = title, dir = dir and (root() .. "/" .. dir) or root() }))
  end)
end

-- Today's journal entry; opens the existing one when it is already there.
function M.today()
  require("zk").new(opts({ dir = root() .. "/journal" }))
end

-- The running todo list, ~/notes/todo.md; the same file every time.
function M.todo()
  require("zk").new(opts({ title = "Todo", template = "todo.md", dir = root() }))
end

-- Open checkboxes with text, anywhere in the notebook. Empty "- [ ]" lines
-- left by the templates are skipped.
M.task_pattern = [[^\s*[-*] \[ \] \S]]

function M.tasks()
  require("telescope.builtin").grep_string({
    cwd = root(), search = M.task_pattern, use_regex = true,
    additional_args = { "--glob", "*.md" }, prompt_title = "Open tasks",
  })
end

-- Tick or untick the checkbox on the current line, or turn the line into a task.
function M.toggle_task()
  local line = vim.api.nvim_get_current_line()
  local indent, bullet, mark, rest = line:match("^(%s*)([-*+]) %[([ xX])%] ?(.*)$")
  if bullet then
    line = indent .. bullet .. (mark == " " and " [x] " or " [ ] ") .. rest
  else
    indent, bullet, rest = line:match("^(%s*)([-*+]) (.*)$")
    if bullet then line = indent .. bullet .. " [ ] " .. rest
    else
      indent, rest = line:match("^(%s*)(.*)$")
      line = indent .. "- [ ] " .. rest
    end
  end
  vim.api.nvim_set_current_line((line:gsub("%s+$", "")))
end

function M.find()
  require("zk").edit(opts({ sort = { "modified" } }), { title = "Notes" })
end

function M.search()
  ask("Search notes: ", function(query)
    require("zk").edit(opts({ sort = { "modified" }, match = { query } }), { title = "Notes: " .. query })
  end)
end

function M.tags()
  require("zk.commands").get("ZkTags")(opts({ sort = { "note-count" } }))
end

return M
