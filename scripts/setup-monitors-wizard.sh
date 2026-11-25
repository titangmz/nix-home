# shellcheck shell=bash disable=SC2154
# Sourced by setup-monitors.sh; shares its queried outputs and mode selector.
setup_monitor_wizard() {
  if ! command -v gum >/dev/null; then
    printf 'gum is required for the monitor wizard. Run just switch to install it.\n' >&2
    return 1
  fi
  local runtime_file
  runtime_file="${MONITOR_LAYOUT_RUNTIME:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../modules/nixos/desktop/hyprland" && pwd -P)/monitor-layout.lua}"
  [[ -r "$runtime_file" ]] || { printf 'Missing monitor runtime: %s\n' "$runtime_file" >&2; return 1; }

  local active saved='{"version":1,"monitors":[]}' metadata
  active=$(jq -c '
    [.[] | select(.disabled != true)] as $all
    | $all | sort_by([.x // 0, .y // 0, .name])
    | map(. as $m | {
        id: (if ((.description // "") != "" and
          ([$all[] | select(.description == $m.description)] | length) == 1)
          then "desc:" + .description else "name:" + .name end),
        connector: .name, description: (.description // .name),
        label: (.name + " · " + (.description // .name))
      })' <<< "$monitor_json")
  if [[ -r "$destination" ]]; then
    metadata=$(sed -n 's/^-- settings-json: //p' "$destination")
    if [[ -n "$metadata" ]]; then
      if ! jq -e '.version == 1 and (.monitors | type == "array")' >/dev/null <<< "$metadata"; then
        printf 'Invalid saved monitor settings in %s; leaving the file unchanged.\n' "$destination" >&2
        return 1
      fi
      saved="$metadata"
    fi
  fi

  local remaining="$active" ordered='[]' choice record step=1 count
  local -a choices=()
  count=$(jq length <<< "$active")
  while [[ $(jq length <<< "$remaining") -gt 0 ]]; do
    mapfile -t choices < <(jq -r '.[].label' <<< "$remaining")
    choice=$(gum choose --header "Screen $step of $count, from left to right" --select-if-one -- "${choices[@]}") || return 0
    record=$(jq -c --arg label "$choice" '.[] | select(.label == $label)' <<< "$remaining")
    [[ -n "$record" ]] || return 1
    ordered=$(jq -c --argjson record "$record" '. + [$record]' <<< "$ordered")
    remaining=$(jq -c --argjson record "$record" 'map(select(.id != $record.id))' <<< "$remaining")
    step=$((step + 1))
  done

  local main_label main_id previous_main focused_output
  previous_main=$(jq -r '.main // ""' <<< "$saved")
  focused_output=$(jq -r '[.[] | select(.focused == true)][0].name // ""' <<< "$monitor_json")
  main_label=$(jq -r --arg id "$previous_main" --arg focused "$focused_output" '
    (map(select(.id == $id))[0].label) //
    (map(select(.connector == $focused))[0].label) // .[0].label' <<< "$ordered")
  mapfile -t choices < <(jq -r '.[].label' <<< "$ordered")
  main_label=$(gum choose --header 'Which is your main screen? (Startup focus)' --selected "$main_label" --select-if-one -- "${choices[@]}") || return 0
  main_id=$(jq -r --arg label "$main_label" '.[] | select(.label == $label) | .id' <<< "$ordered")

  local chosen='[]' id label suggested workspace used best_mode
  # Ask for the main screen first so a fresh setup naturally starts at 1.
  mapfile -t choices < <(jq -c --arg main "$main_id" 'sort_by(.id != $main) | .[]' <<< "$ordered")
  for record in "${choices[@]}"; do
    id=$(jq -r .id <<< "$record")
    label=$(jq -r .label <<< "$record")
    used=$(jq -cn --argjson old "$saved" --argjson active "$active" --argjson chosen "$chosen" '
      [$old.monitors[] | select(.id as $id | ($active | map(.id) | index($id)) == null) | .workspace]
      + [$chosen[].workspace]')
    suggested=$(jq -rn --arg id "$id" --argjson old "$saved" --argjson used "$used" '
      ([$old.monitors[] | select(.id == $id)][0].workspace // 1) as $previous
      | if ($used | index($previous)) == null then $previous
        else first(range(1;10000) | select(. as $n | ($used | index($n)) == null)) end')
    while true; do
      workspace=$(gum input --header "Default workspace for $label" --prompt 'Workspace > ' --value "$suggested" --char-limit 4) || return 0
      if [[ ! "$workspace" =~ ^[1-9][0-9]{0,3}$ ]]; then
        printf 'Choose a whole number from 1 to 9999.\n' >&2
      elif jq -e --argjson n "$workspace" 'index($n) != null' >/dev/null <<< "$used"; then
        printf 'Workspace %s is already assigned (possibly to a saved disconnected screen).\n' "$workspace" >&2
      else
        break
      fi
    done
    best_mode=$(best_mode_for "$(jq -r .connector <<< "$record")")
    [[ -n "$best_mode" ]] || { printf 'No usable mode for %s\n' "$label" >&2; return 1; }
    record=$(jq -c --argjson workspace "$workspace" --arg mode "$best_mode" '. + {workspace:$workspace, mode:$mode}' <<< "$record")
    chosen=$(jq -c --argjson record "$record" '. + [$record]' <<< "$chosen")
  done
  chosen=$(jq -cn --argjson order "$ordered" --argjson chosen "$chosen" '$order | map(.id as $id | $chosen[] | select(.id == $id))')

  local settings summary action
  # Keep disconnected screens in their previous slots; reorder connected ones.
  settings=$(jq -cn --arg main "$main_id" --argjson old "$saved" --argjson chosen "$chosen" '
    reduce $old.monitors[] as $m ({monitors:[], pending:$chosen};
      if ($chosen | map(.id) | index($m.id)) != null
      then .monitors += [.pending[0]] | .pending = .pending[1:]
      else .monitors += [$m] end)
    | {version:1, main:$main, monitors:(.monitors + .pending)}')
  summary=$(jq -r --arg main "$main_id" '
    ["LEFT → RIGHT  DEFAULT  SCREEN", ""] +
    (to_entries | map("\(.key + 1)            \(.value.workspace)        " +
      .value.connector + (if .value.id == $main then " [Main]" else "" end) +
      "\n                      " + (.value.description[0:36]) +
      (if (.value.description | length) > 36 then "…" else "" end))) | .[]' <<< "$chosen")
  gum style --border rounded --padding '1 2' 'Monitor setup' "$summary" '' \
    'One screen: workspace 1. Open windows are preserved.' \
    'Disconnected screens are remembered. Ctrl-C cancels without saving.'
  action=$(gum choose --header 'Use this setup?' -- 'Save and apply' 'Save for next login' 'Cancel') || return 0
  [[ "$action" != Cancel ]] || return 0

  local destination_dir temporary
  destination_dir=$(dirname "$destination")
  mkdir -p "$destination_dir"
  temporary=$(mktemp "$destination_dir/.local_monitors.lua.XXXXXX")
  trap 'rm -f "$temporary"' EXIT
  {
    printf '%s\n' '-- Machine-local monitor layout and workspace defaults. Re-run just setup-monitors to edit.'
    printf '%s\n' "-- settings-json: $settings"
    printf 'local settings = { main = %s, monitors = {\n' "$(jq -r '.main | @json' <<< "$settings")"
    jq -r '.monitors[] | "    { id = \(.id | @json), connector = \(.connector | @json), description = \(.description | @json), mode = \(.mode | @json), workspace = \(.workspace) },"' <<< "$settings"
    printf '} }\n'
    printf 'dofile(%s)(settings)\n' "$(jq -rn --arg path "$runtime_file" '$path | @json')"
  } > "$temporary"
  chmod 0644 "$temporary"
  if [[ -f "$destination" ]] && cmp -s "$temporary" "$destination"; then
    rm -f "$temporary"
    printf 'Monitor setup already matches %s\n' "$destination"
  else
    mv -f "$temporary" "$destination"
    printf 'Saved %s\n' "$destination"
  fi
  trap - EXIT
  if [[ "$action" == 'Save and apply' ]]; then
    hyprctl reload
  else
    printf 'Apply later with: hyprctl reload\n'
  fi
}
