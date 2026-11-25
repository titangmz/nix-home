"""Check creation of the machine-local Hyprland monitor layout."""

import os
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(os.environ.get(
    "SETUP_MONITORS_SCRIPT", Path(__file__).resolve().parents[1] / "scripts/setup-monitors.sh"
))
BASH = shutil.which("bash")


class SetupMonitorsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-monitors-")
        self.addCleanup(self.temp.cleanup)
        self.destination = Path(self.temp.name) / "config/hypr/local_monitors.lua"
        self.bin = Path(self.temp.name) / "bin"
        self.bin.mkdir()
        hyprctl = self.bin / "hyprctl"
        hyprctl.write_text(
            "#!/bin/sh\n"
            "cat <<'EOF'\n"
            '[{"name":"DP-2","x":2560,"y":0,"width":1920,"height":1080,'
            '"refreshRate":239.76,"description":"Dell Inc. U2723QE","availableModes":'
            '["1920x1080@60.00Hz","1920x1080@239.76Hz","1280x720@240.00Hz"]},'
            '{"name":"eDP-1","x":0,"y":0,"width":2560,"height":1600,'
            '"refreshRate":120,"description":"BOE 0x095F","availableModes":'
            '["2560x1600@60.00Hz","2560x1600@120.00Hz","1920x1080@144.00Hz"]},'
            '{"name":"HDMI-A-9","disabled":true,"x":0,"y":0,"description":"Unused"}]\n'
            "EOF\n"
        )
        hyprctl.chmod(0o755)
        self.env = dict(
            os.environ,
            NIX_HOME_MONITORS_FILE=str(self.destination),
            PATH=f"{self.bin}:{os.environ['PATH']}",
            MONITOR_LAYOUT_RUNTIME=os.environ.get("MONITOR_LAYOUT_RUNTIME", str(Path(__file__).resolve().parents[1] / "modules/nixos/desktop/hyprland/monitor-layout.lua")),
        )

    def wizard(self, responses):
        replies = Path(self.temp.name) / "replies"
        replies.write_text("\n".join(responses) + "\n")
        self.env["GUM_RESPONSES"] = str(replies)
        gum = self.bin / "gum"
        gum.write_text('''#!/bin/sh
if [ "$1" = style ]; then exit 0; fi
answer=$(head -n 1 "$GUM_RESPONSES")
tail -n +2 "$GUM_RESPONSES" > "$GUM_RESPONSES.next"
mv "$GUM_RESPONSES.next" "$GUM_RESPONSES"
[ "$answer" != __CANCEL__ ] || exit 130
printf '%s\\n' "$answer"
''')
        gum.chmod(0o755)
        return self.invoke("--interactive")

    def saved_settings(self):
        line = next(line for line in self.destination.read_text().splitlines() if line.startswith("-- settings-json: "))
        return json.loads(line.removeprefix("-- settings-json: "))

    def test_wizard_separates_position_main_and_workspace(self):
        left, right = "eDP-1 · BOE 0x095F", "DP-2 · Dell Inc. U2723QE"
        result = self.wizard([left, right, right, "1", "2", "Save for next login"])
        self.assertEqual(result.returncode, 0, result.stderr)
        saved = self.saved_settings()
        self.assertEqual(saved["main"], "desc:Dell Inc. U2723QE")
        self.assertEqual([(m["connector"], m["workspace"]) for m in saved["monitors"]], [("eDP-1", 2), ("DP-2", 1)])
        self.assertIn("dofile(", self.destination.read_text())
        self.assertIn("1920x1080@239.76Hz", self.destination.read_text())

    def test_wizard_rejects_duplicates_and_invalid_workspace_numbers(self):
        left, right = "eDP-1 · BOE 0x095F", "DP-2 · Dell Inc. U2723QE"
        result = self.wizard([left, right, right, "0", "1", "1", "-1", "2", "Save for next login"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("already assigned", result.stderr)
        self.assertIn("whole number", result.stderr)
        self.assertEqual([m["workspace"] for m in self.saved_settings()["monitors"]], [2, 1])

    def test_wizard_cancel_leaves_existing_file_unchanged(self):
        self.destination.parent.mkdir(parents=True)
        self.destination.write_text("original\n")
        left, right = "eDP-1 · BOE 0x095F", "DP-2 · Dell Inc. U2723QE"
        result = self.wizard([left, right, right, "1", "2", "Cancel"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.destination.read_text(), "original\n")
        result = self.wizard(["__CANCEL__"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.destination.read_text(), "original\n")

    def test_wizard_retains_disconnected_profiles_and_is_idempotent(self):
        self.destination.parent.mkdir(parents=True)
        saved = {"version": 1, "main": "desc:Offline", "monitors": [
            {"id": "desc:Offline", "connector": "HDMI-A-1", "description": "Offline", "workspace": 4, "mode": "preferred", "label": "Offline"}
        ]}
        self.destination.write_text("-- settings-json: " + json.dumps(saved) + "\n")
        left, right = "eDP-1 · BOE 0x095F", "DP-2 · Dell Inc. U2723QE"
        replies = [left, right, right, "1", "2", "Save for next login"]
        result = self.wizard(replies)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.saved_settings()["monitors"][0], saved["monitors"][0])
        original = self.destination.read_bytes()
        repeated = self.wizard(replies)
        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        self.assertEqual(self.destination.read_bytes(), original)

    def test_wizard_reloads_only_after_save_and_apply(self):
        hyprctl = self.bin / "hyprctl"
        original = hyprctl.read_text()
        log = Path(self.temp.name) / "reload-log"
        self.env["RELOAD_LOG"] = str(log)
        hyprctl.write_text(original.replace("#!/bin/sh\n", '#!/bin/sh\nif [ "$1" = reload ]; then printf "reload\\n" >> "$RELOAD_LOG"; exit 0; fi\n', 1))
        left, right = "eDP-1 · BOE 0x095F", "DP-2 · Dell Inc. U2723QE"
        result = self.wizard([left, right, right, "1", "2", "Save and apply"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(log.read_text(), "reload\n")

    def test_interactive_rejects_other_modes(self):
        self.assertEqual(self.invoke("--interactive", "--list").returncode, 2)
        self.assertEqual(self.invoke("--interactive", "DP-2").returncode, 2)

    def invoke(self, *args):
        return subprocess.run(
            [BASH, str(SCRIPT), *args],
            env=self.env,
            text=True,
            capture_output=True,
        )

    def test_creates_max_resolution_high_refresh_layout_in_argument_order(self):
        result = self.invoke("DP-2", "eDP-1")
        self.assertEqual(result.returncode, 0, result.stderr)
        layout = self.destination.read_text()
        self.assertLess(layout.index('output = "DP-2"'), layout.index('output = "eDP-1"'))
        self.assertIn('position = "0x0"', layout)
        self.assertIn('position = "auto-right"', layout)
        self.assertIn('mode = "1920x1080@239.76Hz"', layout)
        self.assertIn('mode = "2560x1600@120.00Hz"', layout)
        self.assertNotIn('1280x720@240.00', layout)
        self.assertEqual(layout.count('scale = "auto"'), 2)

    def test_orders_connected_outputs_from_left_to_right(self):
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        layout = self.destination.read_text()
        self.assertLess(layout.index('output = "eDP-1"'), layout.index('output = "DP-2"'))

    def test_repeat_with_the_same_layout_succeeds(self):
        first = self.invoke()
        self.assertEqual(first.returncode, 0, first.stderr)
        original = self.destination.read_text()
        second = self.invoke()
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertIn("already matches", second.stdout)
        self.assertEqual(self.destination.read_text(), original)

    def test_existing_layout_is_kept_until_forced(self):
        self.destination.parent.mkdir(parents=True)
        self.destination.write_text("keep me\n")
        kept = self.invoke("DP-2", "eDP-1")
        self.assertEqual(kept.returncode, 0, kept.stderr)
        self.assertIn("Keeping existing", kept.stdout)
        self.assertEqual(self.destination.read_text(), "keep me\n")
        replaced = self.invoke("--force", "DP-2", "eDP-1")
        self.assertEqual(replaced.returncode, 0, replaced.stderr)
        self.assertIn('output = "DP-2"', self.destination.read_text())

    def test_rejects_unsafe_names(self):
        self.assertNotEqual(self.invoke('DP-1"; error("oops")').returncode, 0)
        self.assertFalse(self.destination.exists())

    def test_list_prints_names_without_writing_a_layout(self):
        result = self.invoke("--list")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertLess(result.stdout.index("eDP-1"), result.stdout.index("DP-2"))
        self.assertLess(result.stdout.index("DP-2"), result.stdout.index("HDMI-A-9"))
        self.assertIn("2560x1600 @ 120.00Hz", result.stdout)
        self.assertIn("BOE 0x095F", result.stdout)
        self.assertIn("Dell Inc. U2723QE", result.stdout)
        self.assertIn("disabled", result.stdout)
        self.assertIn("Pass these names", result.stdout)
        self.assertFalse(self.destination.exists())

    def test_list_rejects_layout_arguments(self):
        result = self.invoke("--list", "--force")
        self.assertEqual(result.returncode, 2)
        self.assertFalse(self.destination.exists())
        result = self.invoke("--list", "DP-2")
        self.assertEqual(result.returncode, 2)
        self.assertFalse(self.destination.exists())

    def test_unknown_output_does_not_create_a_layout(self):
        result = self.invoke("DP-9")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Output not found", result.stderr)
        self.assertFalse(self.destination.exists())
        missing_modes = self.invoke("HDMI-A-9")
        self.assertNotEqual(missing_modes.returncode, 0)
        self.assertIn("Output not found", missing_modes.stderr)
        self.assertFalse(self.destination.exists())


if __name__ == "__main__":
    unittest.main()
