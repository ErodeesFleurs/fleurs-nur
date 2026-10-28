import json
import os
import select
import signal
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


TEMPLATE = Path(sys.argv.pop(1)).read_text()
BASH = sys.argv.pop(1)
RUNTIME_PATH = sys.argv.pop(1)


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="openstarbound-tests-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.env = {
            "HOME": str(self.home),
            "PATH": RUNTIME_PATH,
            "TMPDIR": str(self.root),
        }
        self.defaults = self.root / "defaults.json"
        self.defaults.write_text(json.dumps({"extraAssetDirs": []}))
        self.game = self.root / "game"
        (self.game / "libexec").mkdir(parents=True)
        self.launcher = self.root / "openstarbound"
        script = TEMPLATE.replace("@bash@", BASH).replace("@runtimePath@", RUNTIME_PATH)
        script = script.replace("@defaults@", str(self.defaults)).replace("@game@", str(self.game))
        self.launcher.write_text(script)
        self.launcher.chmod(0o755)

    def config(self, **env):
        result = subprocess.run(
            [self.launcher, "--print-bootconfig"], env=self.env | env,
            cwd=self.root, check=True, capture_output=True, text=True,
        )
        return json.loads(result.stdout)

    def test_untrusted_paths_are_data_not_shell_or_json(self):
        marker = self.root / "injected"
        assets = str(self.root / 'assets"\\\n, "storageDirectory": "injected')
        storage = f"$HOME/save'; touch {marker}; #$(touch {marker})"
        extra = str(self.root / "mod:with\nnewline")
        self.defaults.write_text(json.dumps({
            "starboundAssetsPath": assets, "storageDir": storage,
            "logDir": "${HOME}/logs", "modDir": "~/mods",
            "extraAssetDirs": [extra, "$XDG_DATA_HOME/custom", "${XDG_DATA_HOME}/other"],
        }))
        result = self.config()
        self.assertEqual(result, {
            "assetDirectories": [assets, str(self.game / "share/openstarbound/assets"),
                                 extra, str(self.home / ".local/share/custom"),
                                 str(self.home / ".local/share/other"), str(self.home / "mods")],
            "storageDirectory": str(self.home) + storage[len("$HOME"):],
            "logDirectory": str(self.home / "logs"),
        })
        self.assertFalse(marker.exists())
        self.assertEqual(list(self.root.glob("openstarbound.*")), [])

    def test_environment_precedence_and_existing_save_location(self):
        self.defaults.write_text(json.dumps({"starboundAssetsPath": "/configured", "extraAssetDirs": []}))
        default = self.config()
        self.assertEqual(default["assetDirectories"][0], "/configured")
        self.assertEqual(default["storageDirectory"], str(self.home / ".local/share/OpenStarbound/storage"))
        overridden = self.config(
            OPENSTARBOUND_ASSETS="/new",
            OPENSTARBOUND_STORAGE="relative/save", OPENSTARBOUND_LOGS="/logs",
            OPENSTARBOUND_MODS="/mods",
        )
        self.assertEqual(overridden["assetDirectories"][0], "/new")
        self.assertEqual(overridden["storageDirectory"], str(self.root / "relative/save"))
        self.assertEqual(overridden["logDirectory"], "/logs")
        self.assertEqual(overridden["assetDirectories"][-1], "/mods")

    def test_private_config_lives_until_engine_exit_then_is_removed(self):
        # Simulate a delayed consumer, not a successful exec that never reads
        # the config: the wrapper must retain the file for the whole lifetime.
        engine = self.game / "libexec/starbound"
        engine.write_text(f"#!{sys.executable}\n" + '''
import json, os, stat, sys, time
from pathlib import Path
config = Path(sys.argv[2])
assert stat.S_IMODE(config.parent.stat().st_mode) == 0o700
first = config.read_bytes()
assert json.loads(first)["storageDirectory"].endswith("/OpenStarbound/storage")
time.sleep(0.1)
assert config.read_bytes() == first
assert Path(json.loads(first)["storageDirectory"]).is_dir()
sys.exit(23)
''')
        engine.chmod(0o755)
        processes = [subprocess.Popen([self.launcher], env=self.env, cwd=self.root) for _ in range(2)]
        try:
            self.assertEqual([p.wait(timeout=10) for p in processes], [23, 23])
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
                    process.wait()
        self.assertEqual(list(self.root.glob("openstarbound.*")), [])

    def test_interrupt_reaches_engine_and_cleans_private_config(self):
        engine = self.game / "libexec/starbound"
        engine.write_text(f"#!{sys.executable}\n" + '''
import os, signal
print(os.getpid(), flush=True)
signal.pause()
''')
        engine.chmod(0o755)
        process = subprocess.Popen(
            [self.launcher], env=self.env, cwd=self.root,
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
        )
        child = None
        try:
            self.assertTrue(select.select([process.stdout], [], [], 5)[0], "engine did not start")
            child = int(process.stdout.readline())
            process.send_signal(signal.SIGINT)
            self.assertEqual(process.wait(timeout=5), 130)
            with self.assertRaises(ProcessLookupError):
                os.kill(child, 0)
            self.assertEqual(list(self.root.glob("openstarbound.*")), [])
        finally:
            if child is not None:
                try:
                    os.kill(child, signal.SIGKILL)
                except ProcessLookupError:
                    pass
            if process.poll() is None:
                process.kill()
                process.wait()
            process.stdout.close()


if __name__ == "__main__":
    unittest.main()
