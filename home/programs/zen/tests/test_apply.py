import json
import os

import zen_profile as zp
from conftest import DOCS, FOLDER_ID


def find(diffs, ident):
    return next(d for d in diffs if d.ident == ident)


def test_promote_setting_to_shared_and_profile(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    res = zp.apply(profile, repo, [zp.Action(find(diffs, "test.pref"), "promote", "shared"),
                                   zp.Action(find(diffs, "general.autoScroll"), "promote", "profile")])
    assert repo.load("settings/shared.json", {})["test.pref"] is True
    assert repo.load("settings/personal.json", {}) == {"general.autoScroll": False}
    assert res.written == {"settings/shared.json", "settings/personal.json"}


def test_promote_pin_keeps_bookmarks_unmanaged(world):
    profile, repo = world
    os.remove(repo.path("profiles/personal.json"))
    diffs, _ = zp.diff_profile(profile, repo)
    zp.apply(profile, repo, [zp.Action(find(diffs, DOCS), "promote")])
    data = repo.load("profiles/personal.json", {})
    assert "bookmarks" not in data
    assert [p["id"] for p in data["pins"]] == [DOCS]


def test_promote_bookmark_removed_added_renamed(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    zp.apply(profile, repo, [zp.Action(find(diffs, "Toolbar|https://gone.example/"), "promote"),
                             zp.Action(find(diffs, "Other Bookmarks|https://c.example/"), "promote"),
                             zp.Action(find(diffs, "Toolbar|https://b.example/"), "promote")])
    tree = repo.load("profiles/personal.json", {})["bookmarks"]
    assert zp.flatten_bookmarks(tree) == [
        (("[toolbar]",), "https://a.example/", ""),
        (("[toolbar]",), "https://b.example/", "B"),
        (("Other Bookmarks",), "https://c.example/", "C"),
    ]


def test_promote_toolbar_profile_creates_own_file(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    zp.apply(profile, repo, [zp.Action(find(diffs, "nav-bar"), "promote", "profile")])
    assert repo.load("toolbar-personal.json", {})["placements"]["nav-bar"] == ["back-button", "urlbar-container"]
    assert repo.load("toolbar.json", {})["placements"]["nav-bar"] == ["urlbar-container", "back-button"]


def test_promote_shortcut_updates_baseline(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    zp.apply(profile, repo, [zp.Action(find(diffs, "zen-toggle-sidebar"), "promote")])
    entry = repo.load("shortcuts/shared.json", [])[0]
    assert entry["id"] == "zen-toggle-sidebar" and entry["key"] == "x" and entry["modifiers"]["alt"] is True
    assert zp.read_baseline(profile.file(zp.BASELINE))["zen-toggle-sidebar"]["key"] == "x"


def test_ignore_writes_ignore_list(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    zp.apply(profile, repo, [zp.Action(find(diffs, "test.pref"), "ignore")])
    assert "test.pref" in repo.load("settings/ignore.json", {})["setting"]


def test_reverts_edit_files_when_closed(world):
    profile, repo = world
    diffs, _ = zp.diff_profile(profile, repo)
    res = zp.apply(profile, repo, [zp.Action(find(diffs, "test.pref"), "revert"),
                                   zp.Action(find(diffs, FOLDER_ID), "revert"),
                                   zp.Action(find(diffs, "zen-toggle-sidebar"), "revert"),
                                   zp.Action(find(diffs, "general.autoScroll"), "revert")])
    assert "test.pref" not in zp.read_prefs(profile.file("prefs.js"))
    _, pins, _ = zp.session_pins(zp.load_session(profile.file("zen-sessions.jsonlz4")))
    assert FOLDER_ID not in {p["id"] for p in pins}
    assert DOCS in {p["id"] for p in pins} and next(p for p in pins if p["id"] == DOCS)["folderParentId"] is None
    assert zp.read_shortcuts(profile.file("zen-keyboard-shortcuts.json"))["zen-toggle-sidebar"]["key"] == "b"
    assert [d.ident for d in res.restart] == ["general.autoScroll"]
    assert os.path.exists(profile.file("prefs.js.pre-reconcile"))


def test_reverts_queue_while_zen_runs(world):
    profile, repo = world
    os.symlink(f"127.0.0.2:+{os.getpid()}", profile.file("lock"))
    diffs, _ = zp.diff_profile(profile, repo)
    res = zp.apply(profile, repo, [zp.Action(find(diffs, "test.pref"), "revert")])
    assert [d.ident for d in res.queued] == ["test.pref"]
    assert "test.pref" in zp.read_prefs(profile.file("prefs.js"))
    assert "close Zen" in zp.summary(res)


def test_adopt_unmanaged_bookmarks(world):
    profile, repo = world
    os.remove(repo.path("profiles/personal.json"))
    diffs, _ = zp.diff_profile(profile, repo)
    rows = [d for d in diffs if d.kind == "bookmark"]
    assert [d.ident for d in rows] == ["adopt"]
    zp.apply(profile, repo, [zp.Action(rows[0], "promote")])
    data = repo.load("profiles/personal.json", {})
    assert data["bookmarks"] == zp.read_bookmarks(profile.file("places.sqlite"))
    assert "pins" not in data and "spaces" not in data


def test_revert_adopt_is_noop(world):
    profile, repo = world
    os.remove(repo.path("profiles/personal.json"))
    diffs, _ = zp.diff_profile(profile, repo)
    row = next(d for d in diffs if d.ident == "adopt")
    res = zp.apply(profile, repo, [zp.Action(row, "revert")])
    assert res.restart == res.switch == res.queued == res.reverted == []
    assert res.written == set()
    assert not os.path.exists(repo.path("profiles/personal.json"))


def test_promote_shared_clears_profile_override(world):
    profile, repo = world
    repo.save("settings/personal.json", {"test.pref": False})
    diffs, _ = zp.diff_profile(profile, repo)
    res = zp.apply(profile, repo, [zp.Action(find(diffs, "test.pref"), "promote", "shared")])
    assert repo.load("settings/shared.json", {})["test.pref"] is True
    assert "test.pref" not in repo.load("settings/personal.json", {})
    assert "settings/personal.json" in res.written
