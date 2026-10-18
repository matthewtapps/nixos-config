import asyncio
import importlib.util
import os
import shutil

import pytest

import zen_profile as zp

ZEN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location("zen_reconcile", os.path.join(ZEN, "zen-reconcile.py"))
zr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(zr)


@pytest.fixture
def split(world, tmp_path):
    profile, checkout = world
    shutil.copytree(checkout.zen, tmp_path / "active")
    return profile, zp.Repo.at(str(tmp_path / "active")), checkout


def by_ident(diffs):
    return {d.ident: d for d in diffs}


def test_checkout_edit_marks_row_pending(split):
    profile, active, checkout = split
    checkout.save("settings/shared.json", {"zen.glance.enabled": False, "test.pref": True})
    rows = by_ident(zp.reconcile(profile, active, checkout)[0])
    assert rows["test.pref"].extra["pending"] is True
    assert rows["general.autoScroll"].extra["pending"] is False


def test_promote_writes_checkout_and_leaves_active(split):
    profile, active, checkout = split
    diffs, _ = zp.reconcile(profile, active, checkout)
    zp.apply(profile, checkout, [zp.Action(by_ident(diffs)["nav-bar"], "promote")])
    assert active.load("toolbar.json", {})["placements"]["nav-bar"] == ["urlbar-container", "back-button"]
    assert by_ident(zp.reconcile(profile, active, checkout)[0])["nav-bar"].extra["pending"] is True


def test_ignore_in_checkout_is_pending_until_switch(split):
    profile, active, checkout = split
    diffs, _ = zp.reconcile(profile, active, checkout)
    zp.apply(profile, checkout, [zp.Action(by_ident(diffs)["test.pref"], "ignore")])
    assert by_ident(zp.reconcile(profile, active, checkout)[0])["test.pref"].extra["pending"] is True


def test_read_only_reverts_without_checkout(split):
    profile, active, _ = split
    diffs, notes = zp.reconcile(profile, active, None)
    assert any("read-only" in n for n in notes)
    zp.apply(profile, None, [zp.Action(by_ident(diffs)["test.pref"], "revert")])
    assert "test.pref" not in zp.read_prefs(profile.file("prefs.js"))
    with pytest.raises(ValueError, match="read-only"):
        zp.apply(profile, None, [zp.Action(by_ident(diffs)["test.pref"], "promote")])


def run(app, *keys, select=None):
    async def go():
        async with app.run_test() as pilot:
            if select:
                idx = [d.ident for d in app.visible()].index(select)
                app.table.move_cursor(row=idx)
                await pilot.pause()
            await pilot.press(*keys)
            await pilot.pause()
    asyncio.run(go())


def test_tui_shows_pending_after_promote(split):
    profile, active, checkout = split
    app = zr.ReconcileApp(checkout, [profile], active=active)
    run(app, "p", "a", "y", "escape", select="test.pref")
    assert by_ident(app.diffs)["test.pref"].extra["pending"] is True
    assert "pending switch" in app.row_change(by_ident(app.diffs)["test.pref"])


def test_tui_read_only_refuses_promote(split):
    profile, active, _ = split
    app = zr.ReconcileApp(None, [profile], active=active)
    run(app, "p", select="test.pref")
    assert app.marks == {}
