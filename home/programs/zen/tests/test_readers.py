import json
import os

import zen_profile as zp
from conftest import pref_line


def test_read_prefs_handles_escapes_and_json_strings(tmp_path):
    p = tmp_path / "prefs.js"
    p.write_text("// x\n" + pref_line("a.b", 'say "hi"') + pref_line("c", 3)
                 + pref_line("d", json.dumps({"k": [1]})) + "user_pref(\"e\", true);\n")
    assert zp.read_prefs(str(p)) == {"a.b": 'say "hi"', "c": 3, "d": '{"k": [1]}', "e": True}


def test_remove_prefs_backs_up(tmp_path):
    p = tmp_path / "prefs.js"
    p.write_text(pref_line("a", 1) + pref_line("b", 2))
    zp.remove_prefs(str(p), {"a"})
    assert zp.read_prefs(str(p)) == {"b": 2}
    assert (tmp_path / "prefs.js.pre-reconcile").exists()


def test_zen_running(tmp_path):
    assert not zp.zen_running(str(tmp_path))
    os.symlink(f"127.0.0.2:+{os.getpid()}", tmp_path / "lock")
    assert zp.zen_running(str(tmp_path))
    os.remove(tmp_path / "lock")
    os.symlink("127.0.0.2:+999999999", tmp_path / "lock")
    assert not zp.zen_running(str(tmp_path))


def test_discover_and_repo(world):
    profile, repo = world
    assert profile.name == "Personal" and profile.key == "personal"
    assert repo.toolbar_file("personal") == "toolbar.json"
    assert repo.load("missing.json", {"x": 1}) == {"x": 1}


def test_shortcuts_and_baseline(world):
    profile, _ = world
    live = zp.read_shortcuts(profile.file("zen-keyboard-shortcuts.json"))
    base = zp.read_baseline(profile.file("zen-shortcuts-baseline.json"))
    assert live["zen-toggle-sidebar"]["key"] == "x" and base["zen-toggle-sidebar"]["key"] == "b"
