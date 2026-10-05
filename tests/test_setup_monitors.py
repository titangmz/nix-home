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
            '[{"name":"DP-2","availableModes":'
            '["1920x1080@60.00Hz","1920x1080@239.76Hz","1280x720@240.00Hz"]},'
            '{"name":"eDP-1","availableModes":'
            '["2560x1600@60.00Hz","2560x1600@120.00Hz","1920x1080@144.00Hz"]}]\n'
            "EOF\n"
        )
        hyprctl.chmod(0o755)
        self.env = dict(
            os.environ,
            NIX_HOME_MONITORS_FILE=str(self.destination),
            PATH=f"{self.bin}:{os.environ['PATH']}",
        )

    def invoke(self, *outputs):
        return subprocess.run(
            [BASH, str(SCRIPT), *outputs],
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

    def test_existing_layout_is_not_overwritten(self):
        self.destination.parent.mkdir(parents=True)
        self.destination.write_text("keep me\n")
        result = self.invoke("DP-1", "eDP-1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Refusing to overwrite", result.stderr)
        self.assertEqual(self.destination.read_text(), "keep me\n")

    def test_requires_outputs_and_rejects_unsafe_names(self):
        self.assertNotEqual(self.invoke().returncode, 0)
        self.assertNotEqual(self.invoke('DP-1"; error("oops")').returncode, 0)
        self.assertFalse(self.destination.exists())

    def test_unknown_output_does_not_create_a_layout(self):
        result = self.invoke("HDMI-A-9")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Output not found", result.stderr)
        self.assertFalse(self.destination.exists())


if __name__ == "__main__":
    unittest.main()
