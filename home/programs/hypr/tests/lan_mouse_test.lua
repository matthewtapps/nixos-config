package.path = "home/programs/hypr/hyprland/?.lua;" .. package.path
local M = require("lan_mouse")

local function same(a, b)
  return a.x == b.x and a.y == b.y
end

-- pickTarget: last peer wins while it is a target.
local targets = "right tehol\nleft mappo\n"
assert(M.pickTarget("mappo", targets).peer == "mappo")
assert(M.pickTarget("mappo\n", targets).side == "left")
-- last peer offline or unplaced: first line, already in fallback order.
assert(M.pickTarget("kruppe", targets).peer == "tehol")
assert(M.pickTarget(nil, targets).peer == "tehol")
assert(M.pickTarget("tehol", "") == nil)
assert(M.pickTarget(nil, nil) == nil)

-- edgePoint: Karsa, one 2560x1440 monitor.
local karsa = { { x = 0, y = 0, w = 2560, h = 1440 } }
local approach, edge = M.edgePoint(karsa, "right")
assert(same(approach, { x = 2557, y = 720 }) and same(edge, { x = 2559, y = 720 }))
approach, edge = M.edgePoint(karsa, "left")
assert(same(approach, { x = 2, y = 720 }) and same(edge, { x = 0, y = 720 }))
approach, edge = M.edgePoint(karsa, "top")
assert(same(approach, { x = 1280, y = 2 }) and same(edge, { x = 1280, y = 0 }))
approach, edge = M.edgePoint(karsa, "bottom")
assert(same(approach, { x = 1280, y = 1437 }) and same(edge, { x = 1280, y = 1439 }))

-- Tehol: external monitor left of the laptop panel, different heights.
local tehol = {
  { x = 0, y = 0, w = 2048, h = 1280 },
  { x = -2560, y = 0, w = 2560, h = 1440 },
}
approach, edge = M.edgePoint(tehol, "left")
assert(same(edge, { x = -2560, y = 720 }))
approach, edge = M.edgePoint(tehol, "right")
assert(same(edge, { x = 2047, y = 640 }))
-- Both share y = 0; the first one found is used.
approach, edge = M.edgePoint(tehol, "top")
assert(edge.y == 0)
assert(M.edgePoint({}, "right") == nil)

-- logical: scale and rotation.
local l = M.logical({ position = { x = 0, y = 0 }, size = { width = 3072, height = 1920 }, scale = 1.5, transform = 0 })
assert(l.w == 2048 and l.h == 1280)
l = M.logical({ position = { x = 10, y = 20 }, size = { width = 2560, height = 1440 }, scale = 1, transform = 1 })
assert(l.x == 10 and l.y == 20 and l.w == 1440 and l.h == 2560)

print("lan_mouse ok")
