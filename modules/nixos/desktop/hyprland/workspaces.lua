-- Per-screen workspaces. Screens own blocks of numbered workspaces by their
-- left-to-right slot: the first screen has 1-10, the second 11-20, and so on.
-- Keys and Waybar show only the local number, so every screen has its own 1-10.
local M = { size = 10, external = false }
local managed, pending = {}, false

local function home_slot(id)
    if type(id) ~= "number" or id < 1 then return nil end
    return math.floor((id - 1) / M.size) + 1
end

-- Screens in slot order. Callers that arrange outputs pass their own order;
-- otherwise physical position decides.
local function ordered(order)
    local monitors = hl.get_monitors()
    local by_name, result, taken = {}, {}, {}
    for _, monitor in ipairs(monitors) do by_name[monitor.name] = monitor end
    for _, name in ipairs(order or M.order or {}) do
        if by_name[name] and not taken[name] then
            result[#result + 1] = by_name[name]
            taken[name] = true
        end
    end
    local rest = {}
    for _, monitor in ipairs(monitors) do
        if not taken[monitor.name] then rest[#rest + 1] = monitor end
    end
    table.sort(rest, function(a, b)
        if a.x ~= b.x then return a.x < b.x end
        if a.y ~= b.y then return a.y < b.y end
        return a.name < b.name
    end)
    for _, monitor in ipairs(rest) do result[#result + 1] = monitor end
    return result
end

local function slot_of(name)
    for slot, monitor in ipairs(ordered()) do
        if monitor.name == name then return slot end
    end
    return 1
end

-- The global id of local workspace n on the focused screen. A workspace that
-- was left on another screen by a hotplug is pulled here with its windows.
local function target(n)
    local monitor = hl.get_active_monitor()
    if not monitor then return n end
    local id = (slot_of(monitor.name) - 1) * M.size + n
    local workspace = hl.get_workspace(tostring(id))
    if workspace and workspace.monitor and workspace.monitor.name ~= monitor.name then
        hl.dispatch(hl.dsp.workspace.move({ workspace = id, monitor = monitor.name }))
    end
    return id
end

function M.focus(n)
    hl.dispatch(hl.dsp.focus({ workspace = target(n) }))
end

function M.move_window(n)
    hl.dispatch(hl.dsp.window.move({ workspace = target(n) }))
end

-- Bind each screen's first workspace to it and carry every workspace back to
-- the screen that owns its block. Workspaces whose block has no connected
-- screen stay where Hyprland put them, so their windows remain reachable.
-- opts.order: output names in slot order. opts.main: output to focus when
-- opts.initial is set. Without both, focus stays on the current workspace.
function M.arrange(opts)
    opts = opts or {}
    if opts.order then M.order = opts.order end
    local screens = ordered()
    if #screens == 0 then return end
    local focused = hl.get_active_workspace()
    local focused_id = focused and focused.id
    local previous = {}
    for _, monitor in ipairs(screens) do
        previous[monitor.name] = monitor.active_workspace and monitor.active_workspace.id
    end

    -- Hyprland merges rules and ignores an empty monitor string, so retire
    -- old defaults onto a connected screen instead of clearing them.
    for id in pairs(managed) do
        hl.workspace_rule({ workspace = tostring(id), monitor = screens[1].name,
            default = false, persistent = false })
    end
    managed = {}
    for slot, monitor in ipairs(screens) do
        local first = (slot - 1) * M.size + 1
        hl.workspace_rule({ workspace = tostring(first), monitor = monitor.name,
            default = true, persistent = true })
        managed[first] = true
    end

    -- Moving a workspace carries its windows; never move windows one by one.
    for _, workspace in ipairs(hl.get_workspaces()) do
        local home = screens[home_slot(workspace.id) or 0]
        if home and workspace.monitor and workspace.monitor.name ~= home.name then
            hl.dispatch(hl.dsp.workspace.move({ workspace = workspace.id, monitor = home.name }))
        end
    end

    -- Keep each screen on its own workspace. At startup, an empty one that
    -- Hyprland picked gives way to the screen's first workspace.
    for slot, monitor in ipairs(screens) do
        local id = previous[monitor.name]
        local workspace = id and hl.get_workspace(tostring(id))
        if not workspace or home_slot(id) ~= slot or (opts.initial and workspace.is_empty) then
            id = (slot - 1) * M.size + 1
        end
        hl.dispatch(hl.dsp.focus({ monitor = monitor.name }))
        hl.dispatch(hl.dsp.focus({ workspace = id }))
    end

    if opts.initial and opts.main then
        hl.dispatch(hl.dsp.focus({ monitor = opts.main }))
    elseif focused_id and hl.get_workspace(tostring(focused_id)) then
        hl.dispatch(hl.dsp.focus({ workspace = focused_id }))
    end
end

-- Without the monitor wizard, arrange on startup and after hotplug. The
-- wizard's layout sets M.external and calls arrange once outputs are placed.
function M.setup()
    local function schedule(initial)
        if pending then return end
        pending = true
        hl.timer(function()
            pending = false
            if not M.external then M.arrange({ initial = initial }) end
        end, { timeout = 250, type = "oneshot" })
    end
    hl.on("monitor.added", function() schedule(false) end)
    hl.on("monitor.removed", function() schedule(false) end)
    schedule(true)
end

return M
