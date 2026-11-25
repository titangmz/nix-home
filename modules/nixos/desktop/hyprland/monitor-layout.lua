-- Loaded by the machine-local file written by just setup-monitors.
-- Keep topology decisions here so a saved setup also handles hotplug events.
return function(settings)
    local managed, seen, pending, initialized = {}, {}, false, false

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

        local used, existing, previous, main = {}, {}, {}, ordered[1]
        local focused = hl.get_active_workspace()
        local focused_id = focused and focused.id
        for _, workspace in ipairs(hl.get_workspaces()) do existing[workspace.id] = true end
        for _, item in ipairs(ordered) do
            local monitor, profile = item.monitor, item.profile
            previous[monitor.name] = monitor.active_workspace and monitor.active_workspace.id
            if profile then
                item.workspace = profile.workspace
                used[item.workspace] = true
                if profile.id == settings.main then main = item end
            end
        end
        for _, item in ipairs(ordered) do
            if #ordered == 1 then
                item.workspace = 1
            elseif not item.workspace then
                local current = previous[item.monitor.name]
                if current and current > 0 and not used[current] then
                    item.workspace = current
                else
                    local number = 1
                    while used[number] or existing[number] do number = number + 1 end
                    item.workspace = number
                end
                used[item.workspace] = true
            end
        end

        -- Retire old defaults onto a connected screen. Hyprland merges rules
        -- and ignores an empty monitor string, so clearing with "" would leave
        -- stale bindings to disconnected screens. Current defaults override
        -- these fallback bindings immediately below.
        for number in pairs(managed) do
            hl.workspace_rule({ workspace = tostring(number), monitor = main.monitor.name,
                default = false, persistent = false })
        end
        managed = {}
        for index, item in ipairs(ordered) do
            hl.monitor({
                output = item.monitor.name,
                mode = item.profile and item.profile.mode or "preferred",
                position = index == 1 and "0x0" or "auto-right",
                scale = "auto",
            })
            hl.workspace_rule({ workspace = tostring(item.workspace), monitor = item.monitor.name,
                default = true, persistent = true })
            managed[item.workspace] = true
        end
        -- Moving a workspace carries its windows with it; never rename a
        -- workspace or move individual windows between numbered workspaces.
        for _, item in ipairs(ordered) do
            local workspace = hl.get_workspace(tostring(item.workspace))
            if workspace and workspace.monitor and workspace.monitor.name ~= item.monitor.name then
                hl.dispatch(hl.dsp.workspace.move({ workspace = item.workspace, monitor = item.monitor.name }))
            end
            hl.dispatch(hl.dsp.focus({ monitor = item.monitor.name }))
            hl.dispatch(hl.dsp.focus({ workspace = item.workspace }))
        end
        if not initial then
            for _, item in ipairs(ordered) do
                local id = seen[item.monitor.name] and previous[item.monitor.name]
                local workspace = id and hl.get_workspace(tostring(id))
                if workspace and workspace.monitor and workspace.monitor.name == item.monitor.name then
                    hl.dispatch(hl.dsp.focus({ workspace = id }))
                end
            end
        end
        if not initial and focused_id and hl.get_workspace(tostring(focused_id)) then
            hl.dispatch(hl.dsp.focus({ workspace = focused_id }))
        else
            hl.dispatch(hl.dsp.focus({ workspace = main.workspace }))
        end
        seen = {}
        for _, item in ipairs(ordered) do seen[item.monitor.name] = true end
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
