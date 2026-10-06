"""Exercise the combined NixOS switch without changing the real system."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(os.environ.get(
    "NIXOS_SWITCH_SCRIPT", Path(__file__).resolve().parents[1] / "switch-nixos.sh"
))
BASH = shutil.which("bash")


class NixosSwitchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-nixos-switch-")
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name) / "repo"
        self.repo.mkdir()
        self.runtime = Path(self.temp.name) / "runtime"
        self.runtime.mkdir()
        self.config_home = Path(self.temp.name) / "config"
        shutil.copy2(SCRIPT, self.repo / "switch-nixos.sh")
        self.log = self.repo / "calls"
        for name in ["rebuild.sh", "switch.sh"]:
            script = self.repo / name
            script.write_text(
                f"#!{BASH}\n"
                f"printf '%s|DBUS=%s\\n' \"{name} $*\" \"${{DBUS_SESSION_BUS_ADDRESS-unset}}\" >> \"$NIXOS_SWITCH_TEST_LOG\"\n"
                f"exit \"${{NIXOS_SWITCH_TEST_{name.split('.')[0].upper()}_EXIT:-0}}\"\n"
            )
            script.chmod(0o755)
        self.env = dict(
            os.environ,
            DBUS_SESSION_BUS_ADDRESS="unix:path=/stale/session/bus",
            XDG_RUNTIME_DIR=str(self.runtime),
            XDG_CONFIG_HOME=str(self.config_home),
            NIX_HOME_NIXOS_NO_SUDO="1",
            NIX_HOME_NIXOS_TEST="1",
            NIXOS_SWITCH_TEST_LOG=str(self.log),
        )

    def invoke(self, *args):
        return subprocess.run(
            [BASH, str(self.repo / "switch-nixos.sh"), *args],
            cwd=self.repo, env=self.env, text=True, capture_output=True,
        )

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_builds_then_activates_system_and_desktop(self):
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [
            "rebuild.sh build|DBUS=unix:path=/stale/session/bus",
            "rebuild.sh switch|DBUS=unix:path=/stale/session/bus",
            f"switch.sh --profile nixos-hyprland -b nix-home-backup|DBUS=unix:path={self.runtime}/bus",
        ])
        self.assertEqual((self.config_home / "nix-home/root").read_text(), f"{self.repo}\n")

    def test_dry_run_builds_and_previews_without_activation(self):
        result = self.invoke("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [
            "rebuild.sh build|DBUS=unix:path=/stale/session/bus",
            "switch.sh --profile nixos-hyprland --dry-run -b nix-home-backup|DBUS=unix:path=/stale/session/bus",
        ])
        self.assertFalse((self.config_home / "nix-home/root").exists())

    def test_build_failure_prevents_all_activation(self):
        self.env["NIXOS_SWITCH_TEST_REBUILD_EXIT"] = "23"
        result = self.invoke()
        self.assertEqual(result.returncode, 23)
        self.assertEqual(self.calls(), [
            "rebuild.sh build|DBUS=unix:path=/stale/session/bus",
        ])

    def test_system_activation_failure_prevents_home_activation(self):
        self.env["NIXOS_SWITCH_TEST_REBUILD_EXIT"] = "0"
        first = self.invoke()
        self.assertEqual(first.returncode, 0, first.stderr)
        self.log.unlink()

        # The mock needs to fail only its second call, so replace it with a
        # stateful implementation for this case.
        rebuild = self.repo / "rebuild.sh"
        rebuild.write_text(
            f"#!{BASH}\n"
            "printf '%s|DBUS=%s\\n' \"rebuild.sh $*\" \"${DBUS_SESSION_BUS_ADDRESS-unset}\" >> \"$NIXOS_SWITCH_TEST_LOG\"\n"
            "[[ \"$1\" == build ]]\n"
        )
        rebuild.chmod(0o755)
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [
            "rebuild.sh build|DBUS=unix:path=/stale/session/bus",
            "rebuild.sh switch|DBUS=unix:path=/stale/session/bus",
        ])

    def test_unknown_arguments_are_rejected(self):
        result = self.invoke("--switch-only")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Usage:", result.stderr)
        self.assertFalse(self.log.exists())


if __name__ == "__main__":
    unittest.main()
