"""Check creation of the machine-local Hyprland monitor layout."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(os.environ.get(
    "SETUP_MONITORS_SCRIPT", Path(__file__).resolve().parents[1] / "setup-monitors.sh"
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
        )

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
