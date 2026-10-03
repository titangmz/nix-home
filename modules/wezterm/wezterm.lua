local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.90
config.macos_window_background_blur = 16
-- Linux blur is controlled by the compositor on stable WezTerm releases.
-- JetBrains Mono, Nerd Font symbols, and emoji fallback are bundled with WezTerm.
config.font = wezterm.font("JetBrains Mono")
config.font_size = 13
config.line_height = 1.05
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.initial_cols = 120
config.initial_rows = 32
config.adjust_window_size_when_changing_font_size = false

-- Start the managed shell directly, including when launched from the macOS Dock.
config.default_prog = { "@zsh@", "-l" }
config.scrollback_lines = 10000
config.audible_bell = "Disabled"
config.hide_mouse_cursor_when_typing = true
config.window_close_confirmation = "AlwaysPrompt"
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.switch_to_last_active_tab_when_closing_tab = true

-- Keep default shortcuts and application Ctrl keys, including Blink's Ctrl-Space.
-- Press Ctrl-Shift-a, release, then press the next key within one second.
config.leader = { key = "a", mods = "CTRL|SHIFT", timeout_milliseconds = 1000 }
config.keys = {
  { key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "s", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
  {
    key = "r",
    mods = "LEADER",
    action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false, timeout_milliseconds = 3000 }),
  },
  { key = "t", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = "w", mods = "LEADER", action = act.ShowTabNavigator },
  { key = "y", mods = "LEADER", action = act.ActivateCopyMode },
  { key = "f", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },
  { key = "Space", mods = "LEADER", action = act.QuickSelect },
}

config.key_tables = {
  resize_pane = {
    { key = "h", action = act.AdjustPaneSize({ "Left", 2 }) },
    { key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
    { key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
    { key = "l", action = act.AdjustPaneSize({ "Right", 2 }) },
    { key = "Escape", action = act.PopKeyTable },
    { key = "Enter", action = act.PopKeyTable },
  },
}

wezterm.on("update-right-status", function(window)
  local mode = window:active_key_table()
  if window:leader_is_active() then
    mode = "LEADER"
  end
  window:set_right_status(mode == "resize_pane" and "RESIZE: h j k l / Esc" or mode or "")
end)

return config
