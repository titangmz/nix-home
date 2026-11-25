-- Exercise real topology transitions against a small stateful compositor model.
local runtime = os.getenv("MONITOR_LAYOUT_RUNTIME") or "modules/nixos/desktop/hyprland/monitor-layout.lua"
local monitors, workspaces, rules, handlers, timers = {}, {}, {}, {}, {}
local focused, moves = nil, {}
local function monitor(name, description, x)
    local m = { name = name, description = description, x = x, y = 0 }
    monitors[#monitors + 1] = m
    return m
end
local function workspace(id, m, windows)
    local w = { id = id, monitor = m, windows = windows or {} }
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
hl = {
    get_monitors = function() return monitors end,
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
    dsp = { focus = dispatcher("focus"), workspace = { move = dispatcher("move") } },
    dispatch = function(action)
        local args = action.args
        if action.kind == "move" then
            local w = assert(workspaces[args.workspace])
            moves[#moves + 1] = { workspace = w.id, monitor = args.monitor }
            w.monitor = lookup_monitor(args.monitor)
        elseif args.monitor then
            focused = lookup_monitor(args.monitor)
        else
            local w = workspaces[args.workspace]
            if not w then w = workspace(args.workspace, assert(focused)) end
            focused = w.monitor
            focused.active_workspace = w
        end
    end,
}
local function flush()
    while #timers > 0 do table.remove(timers, 1)() end
end
local left = monitor("DP-1", "Secondary serial-left", 0)
local right = monitor("DP-2", "Main serial-right", 1920)
local first = workspace(1, left, { "browser" })
local second = workspace(2, right, { "editor", "terminal" })
focused = right
local settings = { main = "desc:Main serial-right", monitors = {
    { id = "desc:Secondary serial-left", description = left.description, connector = left.name, workspace = 2, mode = "1920x1080@60Hz" },
    { id = "desc:Main serial-right", description = right.description, connector = right.name, workspace = 1, mode = "1920x1080@60Hz" },
} }
dofile(runtime)(settings)
flush()
assert(first.monitor == right and second.monitor == left, "Defaults must be independent of physical order")
assert(focused == right and right.active_workspace.id == 1, "Main monitor gets startup focus")
assert(left.layout.position == "0x0" and right.layout.position == "auto-right", "Physical order is preserved")
assert(first.windows[1] == "browser" and #second.windows == 2, "Applying defaults must preserve windows")
assert(rules[1].monitor == right.name and rules[2].monitor == left.name)

-- User changes workspace; plugging in another output must preserve that choice.
local extra = workspace(5, left, { "notes" })
focused = left
local third = monitor("HDMI-A-1", "New unsaved screen", 3840)
workspace(7, third)
handlers["monitor.added"]()
handlers["monitor.added"]() -- a burst should queue just one update
assert(#timers == 1, "Hotplug events must be coalesced")
flush()
assert(focused == left and left.active_workspace == extra, "Hotplug must preserve the user's focused workspace")
assert(rules[7].monitor == third.name, "Unknown outputs keep a non-conflicting workspace")

-- Undock to the secondary screen: all existing windows stay reachable.
monitors = { left }
for _, w in pairs(workspaces) do w.monitor = left end
left.active_workspace = first
focused = left
handlers["monitor.removed"]()
flush()
assert(rules[1].monitor == left.name and rules[1].default, "A lone screen defaults to workspace 1")
assert(rules[2].monitor == left.name and not rules[2].persistent, "Disconnected defaults must fall back to a connected screen")
for _, rule in pairs(rules) do assert(rule.monitor == left.name, "No binding may point off-screen") end
assert(workspaces[2] == second and #second.windows == 2, "Undocking must preserve other workspaces and windows")

-- Reconnect through another port: identify the display, not its old connector.
right = monitor("DP-9", "Main serial-right", 1920)
workspace(9, right)
handlers["monitor.added"]()
flush()
assert(rules[1].monitor == "DP-9" and first.monitor == right, "Restore defaults after connector changes")
assert(rules[2].monitor == left.name and second.monitor == left)
assert(first.windows[1] == "browser" and #second.windows == 2)
assert(extra.monitor == left and extra.windows[1] == "notes", "Unconfigured workspaces must not be relocated")
assert(settings.monitors[1].workspace == 2, "Fallback must not overwrite saved settings")

-- At login, outputs can arrive after the first deferred update.
monitors, workspaces, rules, focused = {}, {}, {}, nil
dofile(runtime)(settings)
flush()
local late = monitor("DP-9", "Main serial-right", 0)
workspace(9, late)
focused = late
handlers["monitor.added"]()
flush()
assert(late.active_workspace.id == 1, "The first output must get startup defaults even when it arrives late")
print("monitor-layout: startup, hotplug, single screen, reconnect, focus, and window preservation passed")
