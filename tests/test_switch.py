"""Exercise profile selection without activating a Home Manager configuration."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from urllib.parse import quote


SCRIPT = Path(os.environ.get("SWITCH_SCRIPT", Path(__file__).resolve().parents[1] / "switch.sh"))
BASH = shutil.which("bash")


class SwitchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-switch-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / "repo with spaces #?% café"
        self.repo.mkdir()
        shutil.copy2(SCRIPT, self.repo / "switch.sh")
        self.flake = f"path:{quote(str(self.repo), safe='/')}"
        self.config_home = self.root / "config"
        self.saved = self.config_home / "nix-home/profile"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "calls.jsonl"
        # The mock answers the profile query with the platform, then the profiles for it.
        mock = self.bin / "nix"
        mock.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "with open(os.environ['SWITCH_TEST_LOG'], 'a') as log:\n"
            "    log.write(json.dumps({'args': sys.argv[1:], 'profiles': os.environ.get('NIX_HOME_PROFILES')}) + '\\n')\n"
            "if sys.argv[1] == 'eval':\n"
            "    print(' '.join([os.environ['SWITCH_TEST_SYSTEM'], os.environ['SWITCH_TEST_PROFILES']]).strip(), end='')\n"
            "exit_key = 'SWITCH_TEST_EXIT' if sys.argv[1] == 'eval' else 'SWITCH_TEST_RUN_EXIT'\n"
            "sys.exit(int(os.environ.get(exit_key, '0')))\n"
        )
        mock.chmod(0o755)
        self.env = dict(
            os.environ,
            PATH=f"{self.bin}:{os.environ['PATH']}",
            XDG_CONFIG_HOME=str(self.config_home),
            SWITCH_TEST_LOG=str(self.log),
            SWITCH_TEST_SYSTEM="x86_64-linux",
            SWITCH_TEST_PROFILES="nixos pc server",
        )

    def invoke(self, *args, cwd=None):
        return subprocess.run(
            [BASH, str(self.repo / "switch.sh"), *args], cwd=cwd or self.root,
            env=self.env, text=True, capture_output=True,
        )

    def calls(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def run_call(self):
        calls = [call["args"] for call in self.calls() if call["args"][0] == "run"]
        self.assertEqual(len(calls), 1)
        return calls[0]

    def test_named_profile_on_each_platform_and_directory(self):
        for system in ["x86_64-linux", "aarch64-linux", "aarch64-darwin", "x86_64-darwin"]:
            for cwd in [self.root, self.repo]:
                with self.subTest(system=system, cwd=cwd):
                    self.log.unlink(missing_ok=True)
                    self.env["SWITCH_TEST_SYSTEM"] = system
                    result = self.invoke("server", "--dry-run", "--backup-extension", "backup with spaces", cwd=cwd)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    query, run = self.calls()
                    self.assertEqual(query["args"][:4], ["eval", "--impure", "--raw", "--expr"])
                    self.assertEqual(query["profiles"], str(self.repo / "profiles/default.nix"))
                    self.assertEqual(run["args"], [
                        "run", f"{self.flake}#home-manager", "--", "switch", "--flake",
                        f"{self.flake}#server-{system}", "--dry-run", "--backup-extension", "backup with spaces",
                    ])

    def test_profile_is_remembered_for_later_switches(self):
        result = self.invoke("pc")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.saved.read_text(), "pc\n")
        self.log.unlink()
        result = self.invoke("-b", "backup")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.run_call()[5:], [f"{self.flake}#pc-x86_64-linux", "-b", "backup"])

    def test_naming_another_profile_replaces_the_saved_one(self):
        self.saved.parent.mkdir(parents=True)
        self.saved.write_text("pc\n")
        result = self.invoke("server")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.saved.read_text(), "server\n")
        self.assertEqual(self.run_call()[5], f"{self.flake}#server-x86_64-linux")

    def test_dry_run_does_not_change_the_saved_profile(self):
        self.saved.parent.mkdir(parents=True)
        self.saved.write_text("pc\n")
        result = self.invoke("server", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.saved.read_text(), "pc\n")

    def test_missing_profile_lists_choices_and_does_not_switch(self):
        result = self.invoke("--dry-run")
        self.assertEqual(result.returncode, 1)
        self.assertIn("No profile selected. Profiles for x86_64-linux: nixos pc server", result.stderr)
        self.assertEqual([call["args"][0] for call in self.calls()], ["eval"])
        self.assertFalse(self.saved.exists())

    def test_profile_for_another_platform_is_rejected(self):
        self.env.update(SWITCH_TEST_SYSTEM="aarch64-darwin", SWITCH_TEST_PROFILES="mac server")
        for profile in ["nixos", "unknown"]:
            with self.subTest(profile=profile):
                self.log.unlink(missing_ok=True)
                result = self.invoke(profile)
                self.assertEqual(result.returncode, 1)
                self.assertIn(f"Profile {profile} is not available on aarch64-darwin", result.stderr)
                self.assertIn("mac server", result.stderr)
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
        self.env["SWITCH_TEST_EXIT"] = "23"
        result = self.invoke("server")
        self.assertEqual(result.returncode, 23)
        self.assertEqual(len(self.calls()), 1)
        self.assertFalse(self.saved.exists())

    def test_home_manager_failure_is_preserved(self):
        self.env["SWITCH_TEST_RUN_EXIT"] = "31"
        result = self.invoke("server")
        self.assertEqual(result.returncode, 31)
        self.assertEqual(len(self.calls()), 2)

    def test_missing_nix_has_setup_message(self):
        (self.bin / "nix").unlink()
        (self.bin / "dirname").symlink_to(shutil.which("dirname"))
        self.env["PATH"] = str(self.bin)
        result = self.invoke("server")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Nix is required", result.stderr)
        self.assertEqual(self.calls(), [])


if __name__ == "__main__":
    unittest.main()
