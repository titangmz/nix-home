"""Exercise NixOS bootstrap behavior without touching /etc or activating NixOS."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(os.environ.get(
    "BOOTSTRAP_SCRIPT", Path(__file__).resolve().parents[1] / "bootstrap-nixos.sh"
))
BASH = shutil.which("bash")


class BootstrapNixosTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-bootstrap-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        shutil.copy2(SCRIPT, self.repo / "bootstrap-nixos.sh")
        (self.repo / "modules/nixos/system").mkdir(parents=True)
        (self.repo / "modules/nixos/system/default.nix").write_text("{}\n")
        self.config_dir = self.root / "etc/nixos"
        self.config_dir.mkdir(parents=True)
        self.original = "{ ... }: { imports = [ ./hardware-configuration.nix ]; system.stateVersion = \"26.05\"; }\n"
        (self.config_dir / "configuration.nix").write_text(self.original)
        self.log = self.root / "calls"
        script = self.repo / "switch-nixos.sh"
        script.write_text(
            f"#!{BASH}\n"
            "printf '%s\\n' \"switch-nixos.sh $*\" >> \"$BOOTSTRAP_TEST_LOG\"\n"
            "exit \"${BOOTSTRAP_TEST_SWITCH_NIXOS_EXIT:-0}\"\n"
        )
        script.chmod(0o755)
        self.env = dict(
            os.environ,
            NIX_HOME_BOOTSTRAP_CONFIG_DIR=str(self.config_dir),
            NIX_HOME_BOOTSTRAP_NO_SUDO="1",
            NIX_HOME_BOOTSTRAP_TEST="1",
            BOOTSTRAP_TEST_LOG=str(self.log),
        )

    def invoke(self, *args):
        return subprocess.run(
            [BASH, str(self.repo / "bootstrap-nixos.sh"), *args],
            cwd=self.root, env=self.env, text=True, capture_output=True,
        )

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_bootstrap_preserves_machine_and_activates_in_order(self):
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.config_dir / "machine.nix").read_text(), self.original)
        wrapper = (self.config_dir / "configuration.nix").read_text()
        self.assertIn("# Managed by nix-home bootstrap.", wrapper)
        self.assertIn("./machine.nix", wrapper)
        self.assertIn(str(self.repo / "modules/nixos/system"), wrapper)
        self.assertEqual(self.calls(), ["switch-nixos.sh "])

    def test_second_run_is_idempotent(self):
        first = self.invoke()
        self.assertEqual(first.returncode, 0, first.stderr)
        machine = self.config_dir / "machine.nix"
        machine.write_text("machine settings changed after bootstrap\n")
        self.log.unlink()
        second = self.invoke()
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(machine.read_text(), "machine settings changed after bootstrap\n")
        self.assertEqual(self.calls(), ["switch-nixos.sh "])

    def test_build_failure_prevents_activation(self):
        self.env["BOOTSTRAP_TEST_SWITCH_NIXOS_EXIT"] = "23"
        result = self.invoke()
        self.assertEqual(result.returncode, 23)
        self.assertEqual(self.calls(), ["switch-nixos.sh "])

    def test_existing_machine_file_is_not_overwritten(self):
        machine = self.config_dir / "machine.nix"
        machine.write_text("keep me\n")
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Refusing to overwrite", result.stderr)
        self.assertEqual(machine.read_text(), "keep me\n")
        self.assertFalse(self.log.exists())

    def test_arguments_are_rejected(self):
        result = self.invoke("--force")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Usage:", result.stderr)
        self.assertFalse(self.log.exists())


if __name__ == "__main__":
    unittest.main()
