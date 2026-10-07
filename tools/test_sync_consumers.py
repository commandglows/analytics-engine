import contextlib
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest

from sync_consumers import MANIFEST, sync


class SnapshotChecks(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.host = Path(self.directory.name)
        (self.host / "pubspec.yaml").write_text("name: test_host\n")
        self.files = {"pubspec.yaml": b"name: analytics_actions_flutter\n", "lib/source.dart": b"// source\n"}
        self.manifest = json.dumps({"files": {key: hashlib.sha256(value).hexdigest() for key, value in self.files.items()}}).encode()

    def run_sync(self, check=False):
        with contextlib.redirect_stdout(io.StringIO()):
            sync(self.host, self.files, self.manifest, check)

    def test_snapshot_and_missing_or_changed_file_checks(self):
        self.run_sync()
        self.run_sync(check=True)
        source = self.host / "vendor/analytics_actions_flutter/lib/source.dart"
        source.write_text("// local edit\n")
        with self.assertRaisesRegex(ValueError, "drift"):
            self.run_sync(check=True)
        with self.assertRaisesRegex(ValueError, "edited"):
            self.run_sync()
        self.assertEqual(source.read_text(), "// local edit\n")

    def test_unknown_files_are_not_deleted(self):
        self.run_sync()
        extra = self.host / "vendor/analytics_actions_flutter/private.txt"
        extra.write_text("keep this\n")
        with self.assertRaisesRegex(ValueError, "drift"):
            self.run_sync(check=True)
        with self.assertRaisesRegex(ValueError, "Unmanaged"):
            self.run_sync()
        self.assertTrue(extra.exists())

    def test_manifest_changes_are_detected(self):
        self.run_sync()
        (self.host / "vendor/analytics_actions_flutter" / MANIFEST).write_text("{}")
        with self.assertRaisesRegex(ValueError, "drift"):
            self.run_sync(check=True)

    def test_engine_update_and_managed_source_removal(self):
        self.run_sync()
        self.files = {"pubspec.yaml": b"name: updated\n"}
        self.manifest = b'{"files":{}}'
        self.run_sync()
        self.run_sync(check=True)
        self.assertFalse((self.host / "vendor/analytics_actions_flutter/lib/source.dart").exists())


if __name__ == "__main__":
    unittest.main()
