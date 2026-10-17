--!nonstrict

-- Watchers fire only on a change, so seed from state for a late load.
local doc = noctalia.state.get("lanmouse.doc")
local me = noctalia.state.get("lanmouse.me")
local connected = noctalia.state.get("lanmouse.connected") == true
local cliOk = noctalia.state.get("lanmouse.cli_ok") ~= false

local function render()
  local on = doc ~= nil and me ~= nil and (doc.enabled or {})[me] ~= false
  local status
  if not connected then
    status = noctalia.tr("status.offline")
  elseif not cliOk then
    status = noctalia.tr("status.cli_error")
  elseif not on then
    status = noctalia.tr("status.off")
  else
    status = noctalia.tr("status.ok")
  end

  local placed = 0
  for _, link in ipairs(doc and doc.links or {}) do
    if link.host == me or link.peer == me then
      placed += 1
    end
  end

  barWidget.setTooltip({
    { key = noctalia.tr("tooltip.status"), value = status },
    { key = noctalia.tr("tooltip.peers"), value = tostring(placed) },
  })
  local color = (not connected or not cliOk) and "error" or (on and "on_surface" or "on_surface_variant")
  barWidget.render(ui.glyph({ name = on and "mouse" or "mouse-off", color = color }))
end

for _, key in ipairs({ "lanmouse.doc", "lanmouse.me", "lanmouse.connected", "lanmouse.cli_ok" }) do
  noctalia.state.watch(key, function(value)
    if key == "lanmouse.doc" then
      doc = value
    elseif key == "lanmouse.me" then
      me = value
    elseif key == "lanmouse.connected" then
      connected = value == true
    else
      cliOk = value ~= false
    end
    render()
  end)
end

function onClick()
  noctalia.togglePanel("matt/lan-mouse:panel")
end

function update()
  render()
end

render()
