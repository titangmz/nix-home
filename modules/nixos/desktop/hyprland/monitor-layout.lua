-- Loaded by the machine-local file written by just setup-monitors.
-- Keep topology decisions here so a saved setup also handles hotplug events.
-- Every screen has its own workspaces (workspaces.lua); workspace numbers
-- saved by older setups are ignored.
local workspaces = require("workspaces")

return function(settings)
    local pending, initialized = false, false
    workspaces.external = true

    local function apply(initial)
        local monitors = hl.get_monitors()
        if #monitors == 0 then return end
        initial = initial or not initialized
        local ordered, matched, descriptions = {}, {}, {}
        for _, monitor in ipairs(monitors) do
            descriptions[monitor.description] = (descriptions[monitor.description] or 0) + 1
        end
        -- Unique EDID descriptions survive connector changes. Identical screens
        -- without distinct descriptions deliberately fall back to connectors.
        for _, profile in ipairs(settings.monitors) do
            for _, monitor in ipairs(monitors) do
                local match = profile.id:sub(1, 5) == "desc:"
                    and descriptions[monitor.description] == 1 and monitor.description == profile.description
                if profile.id:sub(1, 5) == "name:" then
                    match = monitor.name == profile.connector and monitor.description == profile.description
                end
                if match and not matched[monitor.name] then
                    ordered[#ordered + 1] = { monitor = monitor, profile = profile }
                    matched[monitor.name] = true
                end
            end
        end
        table.sort(monitors, function(a, b)
            if a.x ~= b.x then return a.x < b.x end
            if a.y ~= b.y then return a.y < b.y end
            return a.name < b.name
        end)
        for _, monitor in ipairs(monitors) do
            if not matched[monitor.name] then ordered[#ordered + 1] = { monitor = monitor } end
        end

        local main, names = ordered[1], {}
        for index, item in ipairs(ordered) do
            if item.profile and item.profile.id == settings.main then main = item end
            names[index] = item.monitor.name
            hl.monitor({
                output = item.monitor.name,
                mode = item.profile and item.profile.mode or "preferred",
                position = index == 1 and "0x0" or "auto-right",
                scale = "auto",
            })
        end
        -- Screens own workspace blocks in this left-to-right order.
        workspaces.arrange({ order = names, main = main.monitor.name, initial = initial })
        initialized = true
    end

    local function schedule(initial)
        if pending then return end
        pending = true
        hl.timer(function()
            pending = false
            apply(initial)
        end, { timeout = 250, type = "oneshot" })
    end
    hl.on("monitor.added", function() schedule(false) end)
    hl.on("monitor.removed", function() schedule(false) end)
    schedule(true)
end
