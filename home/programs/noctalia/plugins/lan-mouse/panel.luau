--!nonstrict
local Layout = require("./layout.luau")

local DRAG_TYPE = "lan-mouse-peer"
local SLOT_W, SLOT_H = 140, 90
local CENTRE_W, CENTRE_H = 200, 110

local doc = noctalia.state.get("lanmouse.doc")
local me = noctalia.state.get("lanmouse.me")
local online = noctalia.state.get("lanmouse.online") or {}
local connected = noctalia.state.get("lanmouse.connected") == true

local function tr(key, subst)
  return noctalia.tr(key, subst)
end

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

-- Draws monitors side by side to a shared scale; vertical offsets are dropped.
local function monitorStrip(host, maxW, maxH)
  local monitors = doc and doc.monitors[host] or {}
  local totalW, tallest = 0, 0
  for _, m in ipairs(monitors) do
    totalW += m.w
    tallest = math.max(tallest, m.h)
  end
  if totalW == 0 then
    return ui.box({ width = maxW, height = 4 })
  end
  local scale = math.min(maxW / totalW, maxH / tallest)
  local sorted = table.clone(monitors)
  table.sort(sorted, function(a, b)
    return a.x < b.x
  end)
  local boxes = {}
  for _, m in ipairs(sorted) do
    table.insert(boxes, ui.box({
      width = math.max(4, math.floor(m.w * scale)),
      height = math.max(4, math.floor(m.h * scale)),
      fill = "primary/0.25",
      radius = 3,
    }))
  end
  return ui.row({ gap = 2, align = "end" }, boxes)
end

local function tile(peer)
  local enabled = Layout.isEnabled(doc, peer)
  local isOnline = online[peer] == true
  local body = ui.column({ gap = 4, padding = 6, align = "stretch" }, {
    ui.row({ gap = 4, align = "center" }, {
      ui.glyph({ name = "circle-filled", size = 8, color = isOnline and "primary" or "outline" }),
      ui.label({
        text = peer,
        fontSize = 12,
        color = enabled and "on_surface" or "on_surface_variant",
        flexGrow = 1,
      }),
      ui.button({
        glyph = "power",
        variant = "ghost",
        tooltip = enabled and tr("panel.disable") or tr("panel.enable"),
        onClick = function()
          request({ kind = "enable", host = peer, on = not enabled })
        end,
      }),
    }),
    monitorStrip(peer, SLOT_W - 16, 36),
  })
  if not enabled then
    return ui.box({ key = `tile-{peer}`, width = SLOT_W, fill = "on_surface/0.04", radius = 8 }, { body })
  end
  return ui.dragSource({
    key = `tile-{peer}`,
    dragType = DRAG_TYPE,
    payload = peer,
    previewAncestor = 0,
    liftFromLayout = true,
    width = SLOT_W,
  }, { ui.box({ fill = "on_surface/0.08", radius = 8 }, { body }) })
end

local function occupant(side)
  for _, peer in ipairs(peers()) do
    if Layout.isEnabled(doc, peer) and Layout.sideOf(doc, me, peer) == side then
      return peer
    end
  end
  return nil
end

local function slot(side)
  local peer = occupant(side)
  local child = peer and tile(peer)
    or ui.label({ text = tr("panel.drop"), fontSize = 10, color = "on_surface_variant" })
  return ui.dropZone({
    key = `slot-{side}`,
    accepts = { DRAG_TYPE },
    value = side,
    onDrop = "onPeerDrop",
    width = SLOT_W,
    height = SLOT_H,
    radius = 8,
  }, { child })
end

local function centre()
  return ui.column({ width = CENTRE_W, height = CENTRE_H, gap = 4, align = "center", justify = "center" }, {
    monitorStrip(me, CENTRE_W - 20, CENTRE_H - 30),
    ui.label({ text = tr("panel.this_host", { host = me }), fontSize = 11 }),
  })
end

local function unplaced()
  local tiles = {}
  for _, peer in ipairs(peers()) do
    if not Layout.isEnabled(doc, peer) or not Layout.sideOf(doc, me, peer) then
      table.insert(tiles, tile(peer))
    end
  end
  return ui.dropZone({
    key = "slot-none",
    accepts = { DRAG_TYPE },
    value = "none",
    onDrop = "onPeerDrop",
    minHeight = SLOT_H,
    radius = 8,
  }, {
    ui.column({ gap = 4, padding = 6, align = "stretch" }, {
      ui.label({ text = tr("panel.unplaced"), fontSize = 11, color = "on_surface_variant" }),
      ui.row({ gap = 6 }, tiles),
    }),
  })
end

local function header(selfOn)
  local status = not connected and tr("status.offline") or (selfOn and tr("status.ok") or tr("status.off"))
  return ui.row({ gap = 6, align = "center" }, {
    ui.glyph({ name = "mouse", color = connected and "primary" or "error" }),
    ui.label({ text = tr("panel.title"), fontSize = 13, fontWeight = "semibold" }),
    ui.label({ text = status, fontSize = 11, color = "on_surface_variant" }),
    ui.spacer({ flexGrow = 1 }),
    ui.toggle({ checked = selfOn, onChange = "onToggleSelf" }),
  })
end

local function render()
  if not doc or not me or not connected then
    panel.render(ui.column({ flexGrow = 1, padding = 12, gap = 8 }, {
      header(false),
      ui.label({ text = tr("status.offline"), color = "on_surface_variant" }),
    }))
    return
  end
  local selfOn = Layout.isEnabled(doc, me)
  local grid = ui.column({ gap = 8, align = "center" }, {
    ui.row({ gap = 8 }, { ui.box({ width = SLOT_W }), slot("top"), ui.box({ width = SLOT_W }) }),
    ui.row({ gap = 8, align = "center" }, { slot("left"), centre(), slot("right") }),
    ui.row({ gap = 8 }, { ui.box({ width = SLOT_W }), slot("bottom"), ui.box({ width = SLOT_W }) }),
  })
  panel.render(ui.column({ flexGrow = 1, padding = 12, gap = 10, align = "stretch" }, {
    header(selfOn),
    grid,
    unplaced(),
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
