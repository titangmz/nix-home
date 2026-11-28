-- Exercise per-screen workspaces against a small stateful compositor model:
-- startup, keys, hotplug, undock, reconnect, and window preservation.
local runtime = os.getenv("MONITOR_LAYOUT_RUNTIME") or "modules/desktop/hyprland/monitor-layout.lua"
package.path = runtime:gsub("[^/]*$", "") .. "?.lua;" .. package.path
local monitors, workspaces, rules, handlers, timers = {}, {}, {}, {}, {}
local focused = nil
local function monitor(name, description, x)
    local m = { name = name, description = description, x = x, y = 0 }
    monitors[#monitors + 1] = m
    return m
end
local function workspace(id, m, windows)
    local w = { id = id, monitor = m, windows = windows or {} }
    w.is_empty = #w.windows == 0
    workspaces[id] = w
    m.active_workspace = w
    return w
end
local function lookup_monitor(name)
    for _, m in ipairs(monitors) do if m.name == name then return m end end
    error("Missing monitor " .. tostring(name))
end
local function dispatcher(kind)
    return function(args) return { kind = kind, args = args } end
end
local function show(id)
    local w = workspaces[id] or workspace(id, assert(focused))
    focused = w.monitor
    focused.active_workspace = w
    return w
end
hl = {
    get_monitors = function()
        local copy = {}
        for i, m in ipairs(monitors) do copy[i] = m end
        return copy
    end,
    get_active_monitor = function() return focused end,
    get_active_workspace = function() return focused and focused.active_workspace end,
    get_workspaces = function()
        local result = {}
        for _, w in pairs(workspaces) do result[#result + 1] = w end
        return result
    end,
    get_workspace = function(id) return workspaces[tonumber(id)] end,
    monitor = function(args) lookup_monitor(args.output).layout = args end,
    workspace_rule = function(args)
        local rule = rules[tonumber(args.workspace)] or {}
        -- Match the compositor: empty monitor strings do not clear bindings.
        for key, value in pairs(args) do
            if key ~= "monitor" or value ~= "" then rule[key] = value end
        end
        rules[tonumber(args.workspace)] = rule
    end,
    on = function(event, callback) handlers[event] = callback end,
    timer = function(callback) timers[#timers + 1] = callback end,
    dsp = {
        focus = dispatcher("focus"),
        workspace = { move = dispatcher("move") },
        window = { move = dispatcher("window") },
    },
    dispatch = function(action)
        local args = action.args
        if action.kind == "move" then
            local w = assert(workspaces[args.workspace])
            w.monitor = lookup_monitor(args.monitor)
            w.monitor.active_workspace = w
        elseif action.kind == "window" then
            local from = focused.active_workspace
            local window = assert(table.remove(from.windows), "No window to move")
            from.is_empty = #from.windows == 0
            local to = show(args.workspace)
            to.windows[#to.windows + 1] = window
            to.is_empty = false
        elseif args.monitor then
            focused = lookup_monitor(args.monitor)
        else
            show(args.workspace)
        end
    end,
}
local function flush()
    while #timers > 0 do table.remove(timers, 1)() end
end
local function load(settings)
    monitors, workspaces, rules, handlers, timers, focused = {}, {}, {}, {}, {}, nil
    package.loaded.workspaces = nil
    local module = require("workspaces")
    module.setup()
    if settings then dofile(runtime)(settings) end
    return module
end

-- Wizard setup: the left screen owns 1-10 even when the right one is main.
local keys = load({ main = "desc:Main serial-right", monitors = {
    { id = "desc:Secondary serial-left", description = "Secondary serial-left", connector = "DP-1", mode = "1920x1080@60Hz" },
    -- Older setups saved workspace numbers; they must not matter.
    { id = "desc:Main serial-right", description = "Main serial-right", connector = "DP-2", mode = "1920x1080@60Hz", workspace = 1 },
} })
local left = monitor("DP-1", "Secondary serial-left", 0)
local right = monitor("DP-2", "Main serial-right", 1920)
local browser = workspace(1, right, { "browser" })
workspace(2, left)
focused = right
flush()
assert(#timers == 0 and rules[1].monitor == left.name and rules[11].monitor == right.name,
    "Screens own workspace blocks in left-to-right order")
assert(browser.monitor == left and browser.windows[1] == "browser", "Workspaces return home with their windows")
assert(left.active_workspace.id == 1 and right.active_workspace.id == 11, "Each screen starts on its own first workspace")
assert(focused == right, "The main screen gets startup focus")
assert(left.layout.position == "0x0" and right.layout.position == "auto-right", "Physical order is preserved")

-- Keys use the focused screen's own numbers.
keys.focus(3)
assert(focused == right and right.active_workspace.id == 13, "Super+3 on the second screen opens its own 3")
focused = left
keys.focus(3)
assert(focused == left and left.active_workspace.id == 3, "Super+3 on the first screen opens its own 3")
keys.focus(1)
keys.move_window(5)
assert(workspaces[5].windows[1] == "browser" and workspaces[5].monitor == left,
    "Super+Shift+5 moves the window to this screen's 5")
focused = right
show(11).windows = { "editor" }
workspaces[11].is_empty = false

-- An unknown screen gets the next block; hotplug keeps the user's focus.
local third = monitor("HDMI-A-1", "New unsaved screen", 3840)
workspace(4, third)
handlers["monitor.added"]()
handlers["monitor.added"]() -- a burst should queue just one update
assert(#timers == 1, "Hotplug events must be coalesced")
flush()
assert(third.active_workspace.id == 21 and rules[21].monitor == third.name, "A new screen gets its own block")
assert(workspaces[4].monitor == left, "A stray workspace returns to its owning screen")
assert(focused == right and right.active_workspace.id == 11, "Hotplug must preserve the focused workspace")

-- Undock to the first screen: every workspace and window stays reachable.
monitors = { left }
for _, w in pairs(workspaces) do w.monitor = left end
focused = left
handlers["monitor.removed"]()
flush()
for _, rule in pairs(rules) do assert(rule.monitor == left.name, "No binding may point off-screen") end
assert(workspaces[11].windows[1] == "editor" and workspaces[11].monitor == left, "Orphaned workspaces keep their windows")
keys.focus(5)
assert(left.active_workspace.id == 5, "A lone screen uses the first block")

-- Reconnect through another port: identify the display, not its connector.
right = monitor("DP-9", "Main serial-right", 1920)
workspace(30, right)
handlers["monitor.added"]()
flush()
assert(workspaces[11].monitor == right and workspaces[13].monitor == right, "Reconnecting returns the screen's workspaces")
assert(workspaces[11].windows[1] == "editor" and workspaces[5].windows[1] == "browser")
assert(rules[11].monitor == "DP-9" and right.active_workspace.id == 11)
focused = right
keys.focus(2)
assert(right.active_workspace.id == 12, "Keys follow the reconnected screen")

-- At login, outputs can arrive after the first deferred update.
load({ main = "desc:Main serial-right", monitors = {
    { id = "desc:Main serial-right", description = "Main serial-right", connector = "DP-9", mode = "preferred" },
} })
flush()
local late = monitor("DP-9", "Main serial-right", 0)
workspace(9, late)
focused = late
handlers["monitor.added"]()
flush()
assert(late.active_workspace.id == 1, "The first output must get startup defaults even when it arrives late")

-- Without the wizard, physical position decides the blocks.
keys = load()
right = monitor("HDMI-A-2", "Right", 1920)
left = monitor("DP-1", "Left", 0)
local work = workspace(1, right, { "terminal" })
workspace(2, left)
focused = right
flush()
assert(rules[1].monitor == "DP-1" and rules[11].monitor == "HDMI-A-2", "Unmanaged layouts order screens by position")
assert(work.monitor == left and work.windows[1] == "terminal", "Startup preserves windows")
assert(right.active_workspace.id == 11, "Each screen shows its own first workspace")
assert(focused == left and left.active_workspace == work, "Without a main screen, focus follows the focused workspace")
focused = right
keys.focus(4)
assert(right.active_workspace.id == 14)
print("monitor-layout: per-screen workspaces at startup, keys, hotplug, undock, reconnect, and login passed")
