import zen_profile as zp
from conftest import DOCS, FOLDER_ID, MAIL

T = zp.TOOLBAR_FOLDER


def rows(diffs):
    return {(d.kind, d.ident, d.change) for d in diffs}


def test_bookmarks_added_removed_renamed_moved_reordered():
    config = [{"name": "Bookmarks Toolbar", "toolbar": True, "bookmarks": [
        {"name": "A", "url": "https://a/"}, {"name": "B", "url": "https://b/"},
        {"name": "Gone", "url": "https://gone/"}, {"name": "M", "url": "https://m/"}]}]
    live = [{"name": "Bookmarks Toolbar", "toolbar": True, "bookmarks": [
        {"name": "B2", "url": "https://b/"}, {"name": "A", "url": "https://a/"},
        {"name": "New", "url": "https://new/"}]},
        {"name": "Dev", "bookmarks": [{"name": "M", "url": "https://m/"}]}]
    got = rows(zp.diff_bookmarks(live, config))
    assert ("bookmark", "Toolbar|https://new/", "added") in got
    assert ("bookmark", "Toolbar|https://gone/", "removed") in got
    assert ("bookmark", "Toolbar|https://b/", "renamed") in got
    assert ("bookmark", "https://m/", "moved") in got
    assert ("bookmark", "order:Toolbar", "reordered") in got


def test_pins_added_removed_changed_and_space(world):
    profile, repo = world
    spaces, pins, _ = zp.session_pins(zp.load_session(profile.file("zen-sessions.jsonlz4")))
    config = repo.load("profiles/personal.json", {})
    got = rows(zp.diff_pins(spaces, pins, config))
    assert ("pin", DOCS, "added") in got
    assert ("pin", FOLDER_ID, "added") in got
    assert ("pin", "33333333-3333-4333-8333-333333333333", "removed") in got
    assert not any(i == MAIL for _, i, _ in got)


def test_pin_title_only_counts_when_edited():
    base = {"id": "x", "title": "Inbox (3)", "editedTitle": False, "url": "u", "position": 1,
            "isEssential": False, "workspace": None, "folderParentId": None}
    live = dict(base, title="Inbox (9)")
    assert zp.diff_pins([], [live], {"pins": [base], "spaces": []}) == []
    assert rows(zp.diff_pins([], [dict(live, editedTitle=True)], {"pins": [base], "spaces": []})) == {("pin", "x", "changed")}


def test_toolbar_treats_missing_and_empty_alike(world):
    profile, repo = world
    prefs = zp.read_prefs(profile.file("prefs.js"))
    got = zp.diff_toolbar(prefs, {"placements": {"nav-bar": ["urlbar-container", "back-button"], "vertical-tabs": []}})
    assert [(d.ident, d.change) for d in got] == [("nav-bar", "changed")]


def test_settings_declared_changed_and_undeclared(world):
    profile, _ = world
    got = zp.diff_settings(zp.read_prefs(profile.file("prefs.js")), zp.read_prefs(profile.file("user.js")))
    by = {d.ident: d for d in got}
    assert by["general.autoScroll"].change == "changed" and by["general.autoScroll"].revert == "restart"
    assert by["test.pref"].change == "added" and by["test.pref"].revert == "edit"
    assert zp.TOOLBAR_PREF not in by


def test_shortcuts_against_baseline(world):
    profile, _ = world
    got = zp.diff_shortcuts(zp.read_shortcuts(profile.file("zen-keyboard-shortcuts.json")),
                            zp.read_baseline(profile.file("zen-shortcuts-baseline.json")))
    assert rows(got) == {("shortcut", "zen-toggle-sidebar", "changed")}


def test_diff_profile_applies_ignores_but_not_to_declared(world):
    profile, repo = world
    repo.save("settings/ignore.json", {"setting": ["app.*", "general.*", "test.pref"], "pin": [DOCS]})
    diffs, notes = zp.diff_profile(profile, repo)
    idents = {d.ident for d in diffs}
    assert "app.update.lastUpdateTime" not in idents and "test.pref" not in idents
    assert "general.autoScroll" in idents
    assert DOCS not in idents
    assert notes == []
