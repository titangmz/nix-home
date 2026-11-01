"""Exercise switch.sh without activating Home Manager or NixOS."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from urllib.parse import quote


SCRIPT = Path(os.environ.get("SWITCH_SCRIPT", Path(__file__).resolve().parents[1] / "scripts/switch.sh"))
BASH = shutil.which("bash")
BACKUP = ["-b", "nix-home-backup"]
STALE_BUS = "unix:path=/stale/session/bus"

# Every mock appends {tool, args, dbus} to the shared log, then exits with
# SWITCH_TEST_<TOOL>_EXIT, or SWITCH_TEST_<TOOL>_<FIRST ARG>_EXIT when set.
MOCK = f"""#!{sys.executable}
import json, os, sys
tool = os.path.basename(sys.argv[0]).split('.')[0]
with open(os.environ['SWITCH_TEST_LOG'], 'a') as log:
    log.write(json.dumps({{'tool': tool, 'args': sys.argv[1:],
                          'dbus': os.environ.get('DBUS_SESSION_BUS_ADDRESS'),
                          'profiles': os.environ.get('NIX_HOME_PROFILES')}}) + '\\n')
if tool == 'nix' and sys.argv[1] == 'eval':
    print(' '.join([os.environ['SWITCH_TEST_SYSTEM'], os.environ['SWITCH_TEST_PROFILES']]).strip(), end='')
key = f"SWITCH_TEST_{{tool.upper()}}_{{sys.argv[1].upper()}}_EXIT"
sys.exit(int(os.environ.get(key, os.environ.get(f"SWITCH_TEST_{{tool.upper()}}_EXIT", '0'))))
"""


class SwitchTestCase(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-switch-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / "repo with spaces #?% café"
        (self.repo / "scripts").mkdir(parents=True)
        shutil.copy2(SCRIPT, self.repo / "scripts/switch.sh")
        self.flake = f"path:{quote(str(self.repo), safe='/')}"
        self.config_home = self.root / "config"
        self.saved = self.config_home / "nix-home/profile"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "calls.jsonl"
        self.mock(self.bin / "nix")
        self.env = dict(
            os.environ,
            PATH=f"{self.bin}:{os.environ['PATH']}",
            XDG_CONFIG_HOME=str(self.config_home),
            SWITCH_TEST_LOG=str(self.log),
            SWITCH_TEST_SYSTEM="x86_64-linux",
            SWITCH_TEST_PROFILES="nixos pc server",
        )
        self.env.pop("NIX_HOME_TEST_NIXOS", None)

    def mock(self, path):
        path.write_text(MOCK)
        path.chmod(0o755)

    def invoke(self, *args, cwd=None):
        return subprocess.run(
            [BASH, str(self.repo / "scripts/switch.sh"), *args], cwd=cwd or self.root,
            env=self.env, text=True, capture_output=True,
        )

    def calls(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def run_call(self):
        calls = [call for call in self.calls() if call["tool"] == "nix" and call["args"][0] == "run"]
        self.assertEqual(len(calls), 1)
        return calls[0]

    def home_switch(self, profile, *args):
        return ["run", f"{self.flake}#home-manager", "--", "switch", "--flake",
                f"{self.flake}#{profile}", *BACKUP, *args]


class SwitchTests(SwitchTestCase):
    def test_named_profile_on_each_platform_and_directory(self):
        for system in ["x86_64-linux", "aarch64-linux", "aarch64-darwin", "x86_64-darwin"]:
            for cwd in [self.root, self.repo]:
                with self.subTest(system=system, cwd=cwd):
                    self.log.unlink(missing_ok=True)
                    self.env["SWITCH_TEST_SYSTEM"] = system
                    result = self.invoke("server", "--dry-run", "--backup-extension", "other suffix", cwd=cwd)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    query, run = self.calls()
                    self.assertEqual(query["args"][:4], ["eval", "--impure", "--raw", "--expr"])
                    self.assertEqual(query["profiles"], str(self.repo / "profiles/default.nix"))
                    self.assertEqual(run["args"], self.home_switch(
                        f"server-{system}", "--dry-run", "--backup-extension", "other suffix"))

    def test_profile_and_checkout_are_remembered(self):
        result = self.invoke("pc")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.saved.read_text(), "pc\n")
        self.assertEqual((self.config_home / "nix-home/root").read_text(), f"{self.repo}\n")
        self.log.unlink()
        result = self.invoke("-v")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.run_call()["args"], self.home_switch("pc-x86_64-linux", "-v"))

    def test_naming_another_profile_replaces_the_saved_one(self):
        self.saved.parent.mkdir(parents=True)
        self.saved.write_text("pc\n")
        result = self.invoke("server")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.saved.read_text(), "server\n")
        self.assertEqual(self.run_call()["args"], self.home_switch("server-x86_64-linux"))

    def test_dry_run_saves_nothing(self):
        self.saved.parent.mkdir(parents=True)
        self.saved.write_text("pc\n")
        result = self.invoke("server", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.saved.read_text(), "pc\n")
        self.assertFalse((self.config_home / "nix-home/root").exists())

    def test_missing_profile_lists_choices_and_does_not_switch(self):
        result = self.invoke("--dry-run")
        self.assertEqual(result.returncode, 1)
        self.assertIn("No profile selected. Profiles for x86_64-linux: nixos pc server", result.stderr)
        self.assertEqual([call["args"][0] for call in self.calls()], ["eval"])
        self.assertFalse(self.saved.exists())

    def test_profile_for_another_platform_is_rejected(self):
        self.env.update(SWITCH_TEST_SYSTEM="aarch64-darwin", SWITCH_TEST_PROFILES="mac server")
        result = self.invoke("pc")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Profile pc is not available on aarch64-darwin. Profiles for aarch64-darwin: mac server",
                      result.stderr)
        self.assertEqual(len(self.calls()), 1)
        self.assertFalse(self.saved.exists())

    def test_malformed_profile_does_not_run_nix(self):
        for profile in ["Server", "../server", "server pc"]:
            with self.subTest(profile=profile):
                result = self.invoke(profile)
                self.assertEqual(result.returncode, 1)
                self.assertIn("Usage:", result.stderr)
                self.assertEqual(self.calls(), [])

    def test_unsupported_platform_does_not_switch(self):
        self.env.update(SWITCH_TEST_SYSTEM="riscv64-linux", SWITCH_TEST_PROFILES="")
        result = self.invoke("server")
        self.assertEqual(result.returncode, 1)
        self.assertIn("No profile supports riscv64-linux", result.stderr)
        self.assertEqual(len(self.calls()), 1)

    def test_failed_platform_detection_stops(self):
        self.env["SWITCH_TEST_NIX_EVAL_EXIT"] = "23"
        result = self.invoke("server")
        self.assertEqual(result.returncode, 23)
        self.assertEqual(len(self.calls()), 1)
        self.assertFalse(self.saved.exists())

    def test_home_manager_failure_is_preserved(self):
        self.env["SWITCH_TEST_NIX_RUN_EXIT"] = "31"
        result = self.invoke("server")
        self.assertEqual(result.returncode, 31)
        self.assertEqual(len(self.calls()), 2)

    def test_missing_nix_points_to_bootstrap(self):
        (self.bin / "nix").unlink()
        (self.bin / "dirname").symlink_to(shutil.which("dirname"))
        self.env["PATH"] = str(self.bin)
        result = self.invoke("server")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Run ./bootstrap.sh PROFILE first", result.stderr)
        self.assertEqual(self.calls(), [])

    def test_nixos_profile_is_refused_outside_nixos(self):
        (self.bin / "uname").write_text(f"#!{BASH}\necho Linux\n")
        (self.bin / "uname").chmod(0o755)
        if Path("/etc/NIXOS").exists():
            self.skipTest("this machine is NixOS")
        result = self.invoke("nixos")
        self.assertEqual(result.returncode, 1)
        self.assertIn("The nixos profile must run on NixOS", result.stderr)
        self.assertEqual(self.calls(), [])


class NixosSwitchTests(SwitchTestCase):
    """The nixos profile builds and activates the system before the home."""

    def setUp(self):
        super().setUp()
        self.mock(self.repo / "scripts/rebuild.sh")
        (self.bin / "uname").write_text(f"#!{BASH}\necho Linux\n")
        (self.bin / "uname").chmod(0o755)
        self.runtime = self.root / "runtime"
        self.env.update(NIX_HOME_TEST_NIXOS="1", NIX_HOME_NO_SUDO="1",
                        XDG_RUNTIME_DIR=str(self.runtime), DBUS_SESSION_BUS_ADDRESS=STALE_BUS)

    def steps(self):
        return [(call["tool"], call["args"][0], call["dbus"]) for call in self.calls()
                if call["args"][0] != "eval"]

    def test_builds_then_activates_system_then_home(self):
        result = self.invoke("nixos")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.steps(), [
            ("rebuild", "build", STALE_BUS),
            ("rebuild", "switch", STALE_BUS),
            ("nix", "run", f"unix:path={self.runtime}/bus"),
        ])
        self.assertEqual(self.run_call()["args"], self.home_switch("nixos-x86_64-linux"))
        self.assertEqual(self.saved.read_text(), "nixos\n")
        self.assertEqual((self.config_home / "nix-home/root").read_text(), f"{self.repo}\n")

    def test_saved_nixos_profile_switches_the_system_too(self):
        self.saved.parent.mkdir(parents=True)
        self.saved.write_text("nixos\n")
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([step[:2] for step in self.steps()],
                         [("rebuild", "build"), ("rebuild", "switch"), ("nix", "run")])

    def test_dry_run_builds_and_previews_without_activation(self):
        result = self.invoke("nixos", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.steps(), [
            ("rebuild", "build", STALE_BUS),
            ("nix", "run", STALE_BUS),
        ])
        self.assertEqual(self.run_call()["args"], self.home_switch("nixos-x86_64-linux", "--dry-run"))
        self.assertFalse(self.saved.exists())

    def test_build_failure_prevents_all_activation(self):
        self.env["SWITCH_TEST_REBUILD_EXIT"] = "23"
        result = self.invoke("nixos")
        self.assertEqual(result.returncode, 23)
        self.assertEqual([step[:2] for step in self.steps()], [("rebuild", "build")])
        self.assertFalse(self.saved.exists())

    def test_system_activation_failure_prevents_home_activation(self):
        self.env["SWITCH_TEST_REBUILD_SWITCH_EXIT"] = "29"
        result = self.invoke("nixos")
        self.assertEqual(result.returncode, 29)
        self.assertEqual([step[:2] for step in self.steps()], [("rebuild", "build"), ("rebuild", "switch")])
        self.assertFalse(self.saved.exists())

    def test_other_profiles_on_nixos_leave_the_system_alone(self):
        result = self.invoke("server")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.steps(), [("nix", "run", STALE_BUS)])


if __name__ == "__main__":
    unittest.main()
