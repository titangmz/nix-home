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

-- A new note from the note template, or the meeting template under meetings/.
function M.new(dir)
  ask(dir == "meetings" and "Meeting title: " or "Note title: ", function(title)
    require("zk").new(opts({ title = title, dir = dir and (root() .. "/" .. dir) or root() }))
  end)
end

-- Today's journal entry; opens the existing one when it is already there.
function M.today()
  require("zk").new(opts({ dir = root() .. "/journal" }))
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
