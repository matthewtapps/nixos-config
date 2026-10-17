--!nonstrict
local Layout = require("./layout.luau")

local DRAG_TYPE = "lan-mouse-peer"
local SLOT_W, SLOT_H = 116, 70
local PEER_W, PEER_H = 64, 32
local CENTRE_W, CENTRE_H = 150, 70

local doc = noctalia.state.get("lanmouse.doc")
local me = noctalia.state.get("lanmouse.me")
local online = noctalia.state.get("lanmouse.online") or {}
local connected = noctalia.state.get("lanmouse.connected") == true

local function request(payload)
  payload.nonce = noctalia.nowMs()
  noctalia.state.set("lanmouse.request", payload)
end

local function peers()
  local out = {}
  for _, host in ipairs(noctalia.getConfig("hosts") or {}) do
    if host ~= me then
      table.insert(out, host)
    end
  end
  return out
end

-- ui.box is a leaf shape and drops children; containers must be row or column.
local function gap(width, height)
  return ui.column({ width = width, height = height }, {})
end

-- Draws monitors side by side to a shared scale; vertical offsets are dropped.
local function monitors(host, maxW, maxH, fill)
  local list = doc and doc.monitors[host] or {}
  local totalW, tallest = 0, 0
  for _, m in ipairs(list) do
    totalW += m.w
    tallest = math.max(tallest, m.h)
  end
  if totalW == 0 then
    return ui.box({ width = maxW, height = math.floor(maxW * 9 / 16), fill = fill, radius = 4 })
  end
  local scale = math.min(maxW / totalW, maxH / tallest)
  local sorted = table.clone(list)
  table.sort(sorted, function(a, b)
    return a.x < b.x
  end)
  local boxes = {}
  for _, m in ipairs(sorted) do
    table.insert(boxes, ui.box({
      width = math.max(6, math.floor(m.w * scale)),
      height = math.max(6, math.floor(m.h * scale)),
      fill = fill,
      radius = 4,
    }))
  end
  return ui.row({ gap = 3, align = "end" }, boxes)
end

local function peer(host)
  local enabled = Layout.isEnabled(doc, host)
  local isOnline = online[host] == true
  local fill = not enabled and "on_surface/0.06" or (isOnline and "primary/0.35" or "on_surface/0.15")
  local text = (enabled and isOnline) and "on_surface" or "on_surface_variant"
  local body = ui.column({ gap = 1, align = "center" }, {
    monitors(host, PEER_W, PEER_H, fill),
    ui.row({ gap = 2, align = "center" }, {
      ui.label({ text = host, fontSize = 11, color = text }),
      ui.button({
        glyph = "power",
        variant = "ghost",
        glyphSize = 12,
        onClick = function()
          request({ kind = "enable", host = host, on = not enabled })
        end,
      }),
    }),
  })
  if not enabled then
    return body
  end
  return ui.dragSource({
    key = `peer-{host}`,
    dragType = DRAG_TYPE,
    payload = host,
    previewAncestor = 0,
    liftFromLayout = true,
  }, { body })
end

local function occupant(side)
  for _, host in ipairs(peers()) do
    if Layout.isEnabled(doc, host) and Layout.sideOf(doc, me, host) == side then
      return host
    end
  end
  return nil
end

local function slot(side)
  local host = occupant(side)
  local child = host and peer(host)
    or ui.box({ width = PEER_W, height = PEER_H, fill = "on_surface/0.05", radius = 4 })
  return ui.dropZone({
    key = `slot-{side}`,
    accepts = { DRAG_TYPE },
    value = side,
    onDrop = "onPeerDrop",
    width = SLOT_W,
    height = SLOT_H,
    radius = 8,
  }, { ui.column({ flexGrow = 1, align = "center", justify = "center" }, { child }) })
end

local function centre()
  return ui.column({ width = CENTRE_W, height = CENTRE_H, gap = 2, align = "center", justify = "center" }, {
    monitors(me, CENTRE_W - 10, CENTRE_H - 20, "primary/0.7"),
    ui.label({ text = me, fontSize = 12, fontWeight = "semibold" }),
  })
end

local function tray()
  local items = {}
  for _, host in ipairs(peers()) do
    if not Layout.isEnabled(doc, host) or not Layout.sideOf(doc, me, host) then
      table.insert(items, peer(host))
    end
  end
  return ui.dropZone({
    key = "slot-none",
    accepts = { DRAG_TYPE },
    value = "none",
    onDrop = "onPeerDrop",
    minHeight = SLOT_H,
    radius = 8,
  }, { ui.row({ gap = 10, padding = 4, justify = "center" }, items) })
end

local function render()
  local ready = doc ~= nil and me ~= nil and connected
  local selfOn = ready and Layout.isEnabled(doc, me)
  local header = ui.row({ gap = 6, align = "center" }, {
    ui.glyph({ name = "mouse", color = ready and "primary" or "error" }),
    ui.label({ text = noctalia.tr("panel.title"), fontSize = 13, fontWeight = "semibold" }),
    ui.spacer({ flexGrow = 1 }),
    ui.toggle({ checked = selfOn, onChange = "onToggleSelf" }),
  })
  if not ready then
    panel.render(ui.column({ flexGrow = 1, padding = 12 }, { header }))
    return
  end
  local grid = ui.column({ gap = 4, align = "center" }, {
    ui.row({ gap = 4 }, { gap(SLOT_W, SLOT_H), slot("top"), gap(SLOT_W, SLOT_H) }),
    ui.row({ gap = 4, align = "center" }, { slot("left"), centre(), slot("right") }),
    ui.row({ gap = 4 }, { gap(SLOT_W, SLOT_H), slot("bottom"), gap(SLOT_W, SLOT_H) }),
  })
  panel.render(ui.column({ flexGrow = 1, padding = 10, gap = 6, align = "stretch" }, {
    header,
    grid,
    tray(),
  }))
end

for _, key in ipairs({ "lanmouse.doc", "lanmouse.me", "lanmouse.online", "lanmouse.connected" }) do
  noctalia.state.watch(key, function(value)
    if key == "lanmouse.doc" then
      doc = value and Layout.normalise(value)
    elseif key == "lanmouse.me" then
      me = value
    elseif key == "lanmouse.online" then
      online = value or {}
    else
      connected = value == true
    end
    render()
  end)
end

function onPeerDrop(payload, value)
  request({ kind = "place", peer = payload, side = value ~= "none" and value or nil })
end

function onToggleSelf(value)
  request({ kind = "enable", host = me, on = value == true })
end

function onOpen()
  render()
end

if doc then
  doc = Layout.normalise(doc)
end
render()
