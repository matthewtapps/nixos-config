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


def test_apply_with_corrupt_repo_json_shows_message(world):
    profile, repo = world
    app = zr.ReconcileApp(repo, [profile])
    seen = {}

    async def go():
        async with app.run_test() as pilot:
            app.table.move_cursor(row=[d.ident for d in app.visible()].index("test.pref"))
            await pilot.pause()
            with open(repo.path("settings/ignore.json"), "w") as f:
                f.write("{bad")
            await pilot.press("p", "a", "y")
            await pilot.pause()
            seen["text"] = str(app.screen.query_one("#dialog").renderable)
            seen["marks"] = dict(app.marks)
    asyncio.run(go())
    assert "Nothing applied" in seen["text"]
    assert seen["marks"]
    assert "test.pref" not in repo.load("settings/shared.json", {})
