"""Exercise bootstrap.sh without installing Nix, touching /etc, or activating anything."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(os.environ.get("BOOTSTRAP_SCRIPT", Path(__file__).resolve().parents[1] / "bootstrap.sh"))
BASH = shutil.which("bash")
PINNED_HASH = re.search(r"^NIX_INSTALLER_SHA256=(\w+)$", SCRIPT.read_text(), re.M).group(1)
PINNED_VERSION = re.search(r"^NIX_VERSION=([\d.]+)$", SCRIPT.read_text(), re.M).group(1)
TOOLS = ["bash", "sh", "cat", "chmod", "cp", "cut", "dirname", "grep", "awk", "install",
         "mkdir", "mktemp", "mv", "rm", "touch", "uname"]
ON_LINUX = sys.platform.startswith("linux")


def executable(path, body):
    path.write_text(f"#!{BASH}\n{body}")
    path.chmod(0o755)


class BootstrapTestCase(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-bootstrap-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / "repo"
        self.repo.mkdir()
        shutil.copy2(SCRIPT, self.repo / "bootstrap.sh")
        self.config_home = self.root / "config"
        self.log = self.root / "calls"
        (self.repo / "scripts").mkdir()
        executable(self.repo / "scripts/switch.sh",
                   "printf '%s\\n' \"switch.sh $*\" >> \"$BOOTSTRAP_TEST_LOG\"\n"
                   "exit \"${BOOTSTRAP_TEST_SWITCH_EXIT:-0}\"\n")
        self.env = dict(os.environ, XDG_CONFIG_HOME=str(self.config_home), BOOTSTRAP_TEST_LOG=str(self.log))

    def invoke(self, *args):
        return subprocess.run([BASH, str(self.repo / "bootstrap.sh"), *args],
                              cwd=self.root, env=self.env, text=True, capture_output=True)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []


class BootstrapHomeTests(BootstrapTestCase):
    def setUp(self):
        super().setUp()
        # PATH holds only basic tools, so the real Nix, curl, and hash tools stay out of reach.
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for tool in TOOLS:
            if found := shutil.which(tool):
                (self.bin / tool).symlink_to(found)
        self.nix_bin = self.root / "nix-bin"
        self.nix_bin.mkdir()
        executable(self.nix_bin / "nix", "exit 0\n")
        self.nix_profile = self.root / "nix-daemon.sh"
        self.tmp = self.root / "tmp"
        self.tmp.mkdir()
        self.env.update(PATH=f"{self.nix_bin}:{self.bin}", TMPDIR=str(self.tmp),
                        NIX_HOME_BOOTSTRAP_NIX_PROFILE=str(self.nix_profile))
        self.env.pop("NIX_HOME_TEST_NIXOS", None)

    def without_nix(self):
        self.env["PATH"] = str(self.bin)
        # The fake installer creates the profile script that puts Nix on PATH.
        installer = (
            "printf 'installer %s\\n' \"$*\" >> \"$BOOTSTRAP_TEST_LOG\"\n"
            f"printf 'export PATH=\"{self.nix_bin}:$PATH\"\\n' > \"{self.nix_profile}\"\n"
        )
        executable(self.bin / "curl",
                   "printf 'curl %s\\n' \"$*\" >> \"$BOOTSTRAP_TEST_LOG\"\n"
                   "while (($#)); do [[ $1 == -o ]] && out=$2; shift; done\n"
                   f"cat > \"$out\" <<'INSTALLER'\n{installer}INSTALLER\n")
        executable(self.bin / "sha256sum", "printf '%s  %s\\n' \"$BOOTSTRAP_TEST_HASH\" \"$1\"\n")
        self.env["BOOTSTRAP_TEST_HASH"] = PINNED_HASH

    def test_ten_runs_keep_one_flakes_line(self):
        for _ in range(10):
            result = self.invoke("server")
            self.assertEqual(result.returncode, 0, result.stderr)
        nix_conf = (self.config_home / "nix/nix.conf").read_text()
        self.assertEqual(nix_conf.count("experimental-features"), 1)
        self.assertIn("nix-command", nix_conf)
        self.assertIn("flakes", nix_conf)
        self.assertEqual(self.calls(), ["switch.sh server"] * 10)

    def test_existing_features_are_not_duplicated(self):
        nix_dir = self.config_home / "nix"
        nix_dir.mkdir(parents=True)
        (nix_dir / "nix.conf").write_text("experimental-features = nix-command flakes\n")
        result = self.invoke("server")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((nix_dir / "nix.conf").read_text(), "experimental-features = nix-command flakes\n")

    def test_partial_features_gain_the_missing_token(self):
        nix_dir = self.config_home / "nix"
        nix_dir.mkdir(parents=True)
        (nix_dir / "nix.conf").write_text("experimental-features = nix-command\n")
        result = self.invoke("server")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((nix_dir / "nix.conf").read_text().strip(), "experimental-features = nix-command flakes")

    def test_missing_nix_is_installed_from_the_pinned_installer(self):
        self.without_nix()
        result = self.invoke("server")
        self.assertEqual(result.returncode, 0, result.stderr)
        download, *rest = self.calls()
        self.assertTrue(download.startswith(
            f"curl -fsSL https://releases.nixos.org/nix/nix-{PINNED_VERSION}/install -o {self.tmp}/"), download)
        self.assertEqual(rest, ["installer --daemon --yes --no-channel-add", "switch.sh server"])
        self.assertEqual(list(self.tmp.iterdir()), [], "The installer was left behind")

    def test_second_run_loads_the_installed_nix_without_reinstalling(self):
        self.without_nix()
        self.assertEqual(self.invoke("server").returncode, 0)
        self.log.unlink()
        result = self.invoke("server")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["switch.sh server"])

    def test_checksum_mismatch_stops_before_running_the_installer(self):
        self.without_nix()
        self.env["BOOTSTRAP_TEST_HASH"] = "0" * 64
        result = self.invoke("server")
        self.assertEqual(result.returncode, 1)
        self.assertIn("does not match its pinned checksum", result.stderr)
        self.assertEqual(len(self.calls()), 1)
        self.assertTrue(self.calls()[0].startswith("curl "))
        self.assertEqual(list(self.tmp.iterdir()), [])

    def test_switch_failure_is_preserved(self):
        self.env["BOOTSTRAP_TEST_SWITCH_EXIT"] = "31"
        result = self.invoke("server")
        self.assertEqual(result.returncode, 31)

    def test_bad_arguments_are_rejected(self):
        for args in [(), ("server", "pc"), ("Server",), ("../server",)]:
            with self.subTest(args=args):
                result = self.invoke(*args)
                self.assertEqual(result.returncode, 1)
                self.assertIn("Usage: bootstrap.sh PROFILE", result.stderr)
                self.assertEqual(self.calls(), [])

    @unittest.skipIf(Path("/etc/NIXOS").exists(), "this machine is NixOS")
    def test_nixos_profile_needs_nixos(self):
        result = self.invoke("nixos")
        self.assertEqual(result.returncode, 1)
        self.assertIn("The nixos profile needs NixOS", result.stderr)
        self.assertEqual(self.calls(), [])

    @unittest.skipUnless(ON_LINUX, "NixOS detection needs Linux")
    def test_other_profiles_on_nixos_skip_the_system_wiring(self):
        self.env["NIX_HOME_TEST_NIXOS"] = "1"
        self.env["NIX_HOME_BOOTSTRAP_CONFIG_DIR"] = str(self.root / "etc/nixos")
        result = self.invoke("server")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["switch.sh server"])
        self.assertFalse((self.root / "etc").exists())


@unittest.skipUnless(ON_LINUX, "the NixOS bootstrap needs GNU coreutils and Linux")
class BootstrapNixosTests(BootstrapTestCase):
    def setUp(self):
        super().setUp()
        (self.repo / "modules/nixos/system").mkdir(parents=True)
        (self.repo / "modules/nixos/system/default.nix").write_text("{}\n")
        self.config_dir = self.root / "etc/nixos"
        self.config_dir.mkdir(parents=True)
        self.original = "{ ... }: { imports = [ ./hardware-configuration.nix ]; system.stateVersion = \"26.05\"; }\n"
        (self.config_dir / "configuration.nix").write_text(self.original)
        nix_bin = self.root / "nix-bin"
        nix_bin.mkdir()
        executable(nix_bin / "nix", "exit 0\n")
        self.env.update(PATH=f"{nix_bin}:{os.environ['PATH']}", NIX_HOME_BOOTSTRAP_CONFIG_DIR=str(self.config_dir),
                        NIX_HOME_NO_SUDO="1", NIX_HOME_TEST_NIXOS="1")

    def test_bootstrap_preserves_machine_and_activates_in_order(self):
        result = self.invoke("nixos")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.config_dir / "machine.nix").read_text(), self.original)
        wrapper = (self.config_dir / "configuration.nix").read_text()
        self.assertIn("# Managed by nix-home bootstrap.", wrapper)
        self.assertIn("./machine.nix", wrapper)
        self.assertIn(str(self.repo / "modules/nixos/system"), wrapper)
        self.assertEqual(self.calls(), ["switch.sh nixos"])

    def test_second_run_is_idempotent(self):
        self.assertEqual(self.invoke("nixos").returncode, 0)
        machine = self.config_dir / "machine.nix"
        machine.write_text("machine settings changed after bootstrap\n")
        self.log.unlink()
        result = self.invoke("nixos")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(machine.read_text(), "machine settings changed after bootstrap\n")
        self.assertEqual(self.calls(), ["switch.sh nixos"])

    def test_build_failure_prevents_activation(self):
        self.env["BOOTSTRAP_TEST_SWITCH_EXIT"] = "23"
        result = self.invoke("nixos")
        self.assertEqual(result.returncode, 23)
        self.assertEqual(self.calls(), ["switch.sh nixos"])

    def test_existing_machine_file_is_not_overwritten(self):
        machine = self.config_dir / "machine.nix"
        machine.write_text("keep me\n")
        result = self.invoke("nixos")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Refusing to overwrite", result.stderr)
        self.assertEqual(machine.read_text(), "keep me\n")
        self.assertEqual(self.calls(), [])


if __name__ == "__main__":
    unittest.main()
