import asyncio
import importlib.util
import os

from textual.widgets import DataTable

ZEN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location("zen_reconcile", os.path.join(ZEN, "zen-reconcile.py"))
zr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(zr)


def run(app, *keys, select=None):
    async def go():
        async with app.run_test() as pilot:
            if select:
                idx = [d.ident for d in app.visible()].index(select)
                app.query_one(DataTable).move_cursor(row=idx)
                await pilot.pause()
            await pilot.press(*keys)
            await pilot.pause()
    asyncio.run(go())


def test_promote_then_apply(world):
    profile, repo = world
    app = zr.ReconcileApp(repo, [profile])
    run(app, "p", "a", "y", "escape", select="test.pref")
    assert repo.load("settings/shared.json", {})["test.pref"] is True


def test_target_toggle_writes_profile_file(world):
    profile, repo = world
    app = zr.ReconcileApp(repo, [profile])
    run(app, "p", "up", "t", "a", "y", "escape", select="test.pref")
    assert repo.load("settings/personal.json", {})["test.pref"] is True


def test_apply_declined_writes_nothing(world):
    profile, repo = world
    app = zr.ReconcileApp(repo, [profile])
    run(app, "p", "a", "n", select="test.pref")
    assert "test.pref" not in repo.load("settings/shared.json", {})
