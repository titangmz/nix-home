"""Check rebuild commands without building or switching the operating system."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(os.environ.get("REBUILD_SCRIPT", Path(__file__).resolve().parents[1] / "rebuild.sh"))
BASH = shutil.which("bash")


class RebuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-rebuild-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo with spaces #?% café"
        self.repo.mkdir()
        shutil.copy2(SCRIPT, self.repo / "rebuild.sh")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "call.json"
        mock = self.bin / "nixos-rebuild"
        mock.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "with open(os.environ['REBUILD_TEST_LOG'], 'w') as log:\n"
            "    json.dump(sys.argv[1:], log)\n"
            "sys.exit(int(os.environ.get('REBUILD_TEST_EXIT', '0')))\n"
        )
        mock.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}", REBUILD_TEST_LOG=str(self.log))

    def invoke(self, *args):
        return subprocess.run([BASH, str(self.repo / "rebuild.sh"), *args], cwd=self.root,
                              env=self.env, text=True, capture_output=True)

    def test_default_only_builds(self):
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.log.read_text()),
                         ["build", "-I", "nixos-config=/etc/nixos/configuration.nix"])

    def test_actions_and_options_are_forwarded(self):
        for action in ["build", "dry-build", "dry-activate", "switch", "boot", "test"]:
            with self.subTest(action=action):
                result = self.invoke(action, "--option", "log-format", "internal-json")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(self.log.read_text()),
                                 [action, "-I", "nixos-config=/etc/nixos/configuration.nix",
                                  "--option", "log-format", "internal-json"])

    def test_invalid_inputs_do_not_rebuild(self):
        for args in [("unknown",), ("",)]:
            with self.subTest(args=args):
                self.assertNotEqual(self.invoke(*args).returncode, 0)
                self.assertFalse(self.log.exists())

    def test_rebuild_failure_is_preserved(self):
        self.env["REBUILD_TEST_EXIT"] = "31"
        self.assertEqual(self.invoke().returncode, 31)

    def test_missing_nixos_rebuild_has_a_message(self):
        (self.bin / "nixos-rebuild").unlink()
        (self.bin / "dirname").symlink_to(shutil.which("dirname"))
        self.env["PATH"] = str(self.bin)
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("run this script on NixOS", result.stderr)
        self.assertFalse(self.log.exists())


if __name__ == "__main__":
    unittest.main()
