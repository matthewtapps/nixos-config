local Layout = require("./layout")

local KNOWN = { karsa = true, tehol = true, mappo = true, kruppe = true, samar = true }

local function count(t)
  local n = 0
  for _ in pairs(t) do
    n += 1
  end
  return n
end

-- normalise drops bad links, self links and duplicate pairs.
local doc = Layout.normalise({
  links = {
    { host = "karsa", peer = "tehol", side = "right" },
    { host = "tehol", peer = "karsa", side = "left" },
    { host = "karsa", peer = "karsa", side = "left" },
    { host = "karsa", peer = "mappo", side = "diagonal" },
    "junk",
  },
})
assert(#doc.links == 1)
assert(count(doc.enabled) == 0 and count(doc.monitors) == 0)
assert(#Layout.normalise(nil).links == 0)

-- view works from both ends of a link.
assert(Layout.view(doc, "karsa", KNOWN).tehol == "right")
assert(Layout.view(doc, "tehol", KNOWN).karsa == "left")
assert(Layout.view(doc, "mappo", KNOWN).karsa == nil)

-- a disabled peer or a disabled self hides the link.
assert(Layout.view(Layout.setEnabled(doc, "tehol", false), "karsa", KNOWN).tehol == nil)
assert(count(Layout.view(Layout.setEnabled(doc, "karsa", false), "karsa", KNOWN)) == 0)
-- setEnabled copies; the original is unchanged.
assert(Layout.isEnabled(doc, "tehol"))

-- unknown hosts never appear.
local typo = Layout.normalise({ links = { { host = "karsa", peer = "baruk", side = "top" } } })
assert(Layout.view(typo, "karsa", KNOWN).baruk == nil)

-- place: onto an empty side, then onto an occupied side swaps.
local placed = Layout.place(doc, "karsa", "mappo", "left")
assert(Layout.sideOf(placed, "karsa", "mappo") == "left")
assert(Layout.sideOf(placed, "karsa", "tehol") == "right")
local swapped = Layout.place(placed, "karsa", "mappo", "right")
assert(Layout.sideOf(swapped, "karsa", "mappo") == "right")
assert(Layout.sideOf(swapped, "karsa", "tehol") == "left")
-- an unplaced peer dropped on an occupied side unplaces the occupant.
local bumped = Layout.place(doc, "karsa", "kruppe", "right")
assert(Layout.sideOf(bumped, "karsa", "kruppe") == "right")
assert(Layout.sideOf(bumped, "karsa", "tehol") == nil)
-- nil unplaces; links between other hosts are untouched.
local other = Layout.normalise({ links = { { host = "tehol", peer = "mappo", side = "top" } } })
local cleared = Layout.place(Layout.place(other, "karsa", "tehol", "left"), "karsa", "tehol", nil)
assert(Layout.sideOf(cleared, "karsa", "tehol") == nil)
assert(Layout.sideOf(cleared, "tehol", "mappo") == "top")

-- placing from the other end clears whoever held the peer's opposite side.
local fromMappo = Layout.place(doc, "mappo", "karsa", "left")
local karsaView = Layout.view(fromMappo, "karsa", KNOWN)
assert(karsaView.mappo == "right" and karsaView.tehol == nil)
assert(Layout.sideOf(fromMappo, "tehol", "karsa") == nil)

-- a document with 2 peers on one side keeps the first link in order.
local clash = Layout.normalise({
  links = {
    { host = "karsa", peer = "tehol", side = "right" },
    { host = "mappo", peer = "karsa", side = "left" },
  },
})
local clashView = Layout.view(clash, "karsa", KNOWN)
assert(clashView.tehol == "right" and clashView.mappo == nil)

-- monitors: scale, rotation, stable order. Tehol's live eDP-1 reports
-- disabled = true, so the flag must not drop it.
local monitors = Layout.logicalMonitors({
  { name = "eDP-1", x = 0, y = 0, width = 3072, height = 1920, scale = 1.5, transform = 0, disabled = true },
  { name = "DP-2", x = -2560, y = 0, width = 2560, height = 1440, scale = 1, transform = 1 },
})
assert(#monitors == 2)
assert(monitors[1].name == "DP-2" and monitors[1].w == 1440 and monitors[1].h == 2560)
assert(monitors[2].w == 2048 and monitors[2].h == 1280)
local withMonitors = Layout.setMonitors(doc, "karsa", monitors)
assert(Layout.sameMonitors(withMonitors.monitors.karsa, monitors))
assert(not Layout.sameMonitors(nil, monitors))
assert(not Layout.sameMonitors({ monitors[1] }, monitors))

-- parseList reads `lan-mouse cli list`.
local clients = Layout.parseList(
  "id 0: tehol:4242 (right) active: true, ips: {100.99.98.66}\n"
    .. "id 3: unknown:4242 (left) active: false, ips: {}\n"
)
assert(#clients == 2)
assert(clients[1].id == 0 and clients[1].host == "tehol" and clients[1].pos == "right" and clients[1].active)
assert(clients[2].id == 3 and clients[2].host == "unknown" and not clients[2].active)

-- plan: remove strays and duplicates, fix position and activation, add missing.
local hook = function(peer)
  return `hook {peer}`
end
local view = { tehol = "left", mappo = "bottom" }
local commands = Layout.plan(view, {
  { id = 0, host = "tehol", pos = "right", active = false },
  { id = 1, host = "tehol", pos = "left", active = true },
  { id = 2, host = "kruppe", pos = "top", active = true },
}, { mappo = "100.1.2.3" }, hook)
local text = {}
for _, c in ipairs(commands) do
  table.insert(text, table.concat(c, " "))
end
local joined = table.concat(text, "\n")
assert(joined == table.concat({
  "set-position 0 left",
  "activate 0",
  "remove-client 1",
  "remove-client 2",
  "add-client --hostname mappo --enter-hook hook mappo --ips 100.1.2.3",
}, "\n"), joined)
-- after a daemon restart every peer is added back; no address means no --ips.
local fresh = Layout.plan({ tehol = "left" }, {}, {}, hook)
assert(#fresh == 1 and table.concat(fresh[1], " ") == "add-client --hostname tehol --enter-hook hook tehol")
assert(#Layout.plan({}, {}, {}, hook) == 0)

-- targets: fallback order, online only.
local lines = Layout.targets({ tehol = "left", mappo = "right", kruppe = "top" }, { tehol = true, mappo = true })
assert(table.concat(lines, ",") == "right mappo,left tehol")

print("layout ok")
