"""Exercise argument handling without activating a Home Manager configuration."""

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
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo with spaces #?% café"
        self.repo.mkdir()
        shutil.copy2(SCRIPT, self.repo / "switch.sh")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "calls.jsonl"
        mock = self.bin / "nix"
        mock.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "with open(os.environ['SWITCH_TEST_LOG'], 'a') as log:\n"
            "    log.write(json.dumps(sys.argv[1:]) + '\\n')\n"
            "if sys.argv[1] == 'eval':\n"
            "    print(os.environ['SWITCH_TEST_SYSTEM'])\n"
            "exit_key = 'SWITCH_TEST_EXIT' if sys.argv[1] == 'eval' else 'SWITCH_TEST_RUN_EXIT'\n"
            "sys.exit(int(os.environ.get(exit_key, '0')))\n"
        )
        mock.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}",
                        SWITCH_TEST_LOG=str(self.log), SWITCH_TEST_SYSTEM="x86_64-linux")

    def invoke(self, *args, cwd=None):
        return subprocess.run(
            [BASH, str(self.repo / "switch.sh"), *args], cwd=cwd or self.root,
            env=self.env, text=True, capture_output=True,
        )

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_supported_platforms_and_working_directories(self):
        for system in ["x86_64-linux", "aarch64-darwin", "x86_64-darwin"]:
            for cwd in [self.root, self.repo]:
                with self.subTest(system=system, cwd=cwd):
                    self.log.unlink(missing_ok=True)
                    self.env["SWITCH_TEST_SYSTEM"] = system
                    result = self.invoke("--dry-run", "--backup-extension", "backup with spaces", cwd=cwd)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(self.calls(), [
                        ["eval", "--impure", "--raw", "--expr", "builtins.currentSystem"],
                        ["run", f"path:{quote(str(self.repo), safe='/')}#home-manager", "--", "switch", "--flake",
                         f"path:{quote(str(self.repo), safe='/')}#{system}", "--dry-run", "--backup-extension", "backup with spaces"],
                    ])

    def test_unsupported_platform_does_not_run_home_manager(self):
        self.env["SWITCH_TEST_SYSTEM"] = "aarch64-linux"
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unsupported system: aarch64-linux", result.stderr)
        self.assertEqual(len(self.calls()), 1)

    def test_failed_platform_detection_stops(self):
        self.env["SWITCH_TEST_EXIT"] = "23"
        result = self.invoke()
        self.assertEqual(result.returncode, 23)
        self.assertEqual(len(self.calls()), 1)

    def test_home_manager_failure_is_preserved(self):
        self.env["SWITCH_TEST_RUN_EXIT"] = "31"
        result = self.invoke()
        self.assertEqual(result.returncode, 31)
        self.assertEqual(len(self.calls()), 2)

    def test_missing_nix_has_setup_message(self):
        (self.bin / "nix").unlink()
        (self.bin / "dirname").symlink_to(shutil.which("dirname"))
        self.env["PATH"] = str(self.bin)
        result = self.invoke()
        self.assertEqual(result.returncode, 1)
        self.assertIn("Nix is required", result.stderr)
        self.assertFalse(self.log.exists())


if __name__ == "__main__":
    unittest.main()
