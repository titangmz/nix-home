"""Check the VPN indicator, the Rofi network menu, and the control center's
network toggles against a fake nmcli."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


DESKTOP = Path(__file__).resolve().parents[1] / "modules/nixos/desktop"
WAYBAR = Path(os.environ.get("WAYBAR_MODULE", DESKTOP / "waybar"))
CONTROL_CENTER = Path(os.environ.get("CONTROL_CENTER_SCRIPT", DESKTOP / "swaync/control-center"))
BASH = shutil.which("bash")

# Answers `connection show [--active]` and `networking` from files, logs every call.
FAKE_NMCLI = """#!/bin/sh
printf '%s\\n' "$*" >> "$FAKE/nmcli.log"
case "$*" in
  *"connection show --active"*) cat "$FAKE/active" ;;
  *"connection show"*) cat "$FAKE/connections" ;;
  "-t networking") cat "$FAKE/networking" ;;
  *"connection up"*) [ -e "$FAKE/fail" ] && { echo "Error: activation failed" >&2; exit 4; } ;;
esac
exit 0
"""
# Picks the menu row whose text contains $PICK and prints its index, like -format i.
FAKE_ROFI = """#!/bin/sh
cat > "$FAKE/rows"
grep -n -- "$PICK" "$FAKE/rows" | head -n1 | cut -d: -f1 | awk '{ print $1 - 1 }'
"""
FAKE_NOTIFY = """#!/bin/sh
printf '%s\\n' "$*" >> "$FAKE/notify.log"
"""


class NetworkTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-network-")
        self.addCleanup(self.temp.cleanup)
        self.fake = Path(self.temp.name)
        bin_dir = self.fake / "bin"
        bin_dir.mkdir()
        for name, body in (
            ("nmcli", FAKE_NMCLI),
            ("rofi", FAKE_ROFI),
            ("notify-send", FAKE_NOTIFY),
            ("nm-connection-editor", "#!/bin/sh\n: > \"$FAKE/editor\"\n"),
            ("network-menu", "#!/bin/sh\n: > \"$FAKE/network-menu\"\n"),
            ("swaync-client", "#!/bin/sh\n:\n"),
        ):
            path = bin_dir / name
            path.write_text(body)
            path.chmod(0o755)
        self.state(active="", connections="", networking="enabled")
        self.env = dict(os.environ, FAKE=str(self.fake), PATH=f"{bin_dir}:{os.environ['PATH']}")

    def state(self, **files):
        for name, text in files.items():
            (self.fake / name).write_text(text + ("\n" if text else ""))

    def run_script(self, name, *arguments, pick=None, toggle=None):
        env = dict(self.env, PICK=pick or "")
        if toggle is not None:
            env["SWAYNC_TOGGLE_STATE"] = toggle
        script = CONTROL_CENTER if name == "control-center" else WAYBAR / name
        result = subprocess.run(
            [BASH, str(script), *arguments], env=env, text=True, capture_output=True
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def nmcli_calls(self):
        log = self.fake / "nmcli.log"
        return log.read_text().splitlines() if log.exists() else []

    def status(self):
        return json.loads(self.run_script("vpn-status"))

    def test_status_names_the_connected_vpn(self):
        self.state(active="802-3-ethernet:activated:Wired\nvpn:activated:Office: Berlin & Co")
        status = self.status()
        self.assertEqual(status["class"], "connected")
        self.assertIn("Office: Berlin &amp; Co", status["text"])

    def test_status_reports_connecting_and_off(self):
        self.state(active="wireguard:activating:Home")
        self.assertEqual(self.status()["class"], "connecting")
        self.state(active="802-3-ethernet:activated:Wired")
        self.assertEqual(self.status()["class"], "disconnected")

    def test_menu_connects_an_inactive_vpn_and_reports_it(self):
        self.state(connections="u1:802-3-ethernet:activated:Wired\nu2:vpn::Office")
        self.run_script("network-menu", pick="Office")
        self.assertIn("connection up uuid u2", self.nmcli_calls())
        self.assertIn("Connected to Office", (self.fake / "notify.log").read_text())

    def test_menu_disconnects_an_active_vpn(self):
        self.state(connections="u2:vpn:activated:Office")
        self.run_script("network-menu", pick="Office")
        self.assertIn("connection down uuid u2", self.nmcli_calls())

    def test_failed_connection_shows_the_error(self):
        self.state(connections="u2:vpn::Office", fail="")
        self.run_script("network-menu", pick="Office")
        notes = (self.fake / "notify.log").read_text()
        self.assertIn("Couldn't connect to Office", notes)
        self.assertIn("activation failed", notes)

    def test_menu_toggles_networking(self):
        self.run_script("network-menu", pick="Networking is on")
        self.assertIn("networking off", self.nmcli_calls())
        self.state(networking="disabled")
        self.run_script("network-menu", pick="Networking is off")
        self.assertIn("networking on", self.nmcli_calls())

    def test_dismissing_the_menu_changes_nothing(self):
        self.state(connections="u2:vpn::Office")
        self.run_script("network-menu", pick="no such row")
        self.assertFalse(any(call.startswith(("connection up", "connection down", "networking ")) for call in self.nmcli_calls()))

    def test_vpn_toggle_reconnects_the_most_recently_used_vpn(self):
        self.state(connections="100:u1:vpn:Old\n300:u3:802-3-ethernet:Wired\n200:u2:wireguard:Recent")
        self.run_script("control-center", "vpn", toggle="true")
        self.assertIn("connection up uuid u2", self.nmcli_calls())

    def test_vpn_toggle_off_disconnects_every_active_vpn(self):
        self.state(active="u1:vpn:Office\nu3:802-3-ethernet:Wired\nu2:wireguard:Home")
        self.run_script("control-center", "vpn", toggle="false")
        calls = self.nmcli_calls()
        self.assertIn("connection down uuid u1", calls)
        self.assertIn("connection down uuid u2", calls)
        self.assertNotIn("connection down uuid u3", calls)

    def test_vpn_toggle_without_any_vpn_opens_the_network_menu(self):
        self.state(connections="300:u3:802-3-ethernet:Wired")
        self.run_script("control-center", "vpn", toggle="true")
        self.assertFalse(any(call.startswith("connection up") for call in self.nmcli_calls()))
        self.assertTrue((self.fake / "network-menu").exists())

    def test_toggle_states_follow_networkmanager(self):
        self.state(active="u3:802-3-ethernet:Wired")
        self.assertEqual(self.run_script("control-center", "vpn-state").strip(), "false")
        self.state(active="u1:vpn:Office")
        self.assertEqual(self.run_script("control-center", "vpn-state").strip(), "true")
        self.state(networking="disabled")
        self.assertEqual(self.run_script("control-center", "networking-state").strip(), "false")


if __name__ == "__main__":
    unittest.main()
