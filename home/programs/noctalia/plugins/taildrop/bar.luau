--!nonstrict

local doc = nil
local connected = false
local targets = {}

local function preview()
  if not doc or doc.text == "" then
    return noctalia.tr("tooltip.empty")
  end
  local text = doc.text:gsub("%s+", " ")
  if #text > 60 then
    text = text:sub(1, 60) .. "..."
  end
  return text
end

local function render()
  local rows = {
    { key = noctalia.tr("tooltip.buffer"), value = preview() },
    {
      key = noctalia.tr("tooltip.sync"),
      value = connected and noctalia.tr("status.synced_plain") or noctalia.tr("status.offline"),
    },
  }

  local online = 0
  for _, target in ipairs(targets) do
    if target.online then
      online += 1
    end
  end
  table.insert(rows, { key = noctalia.tr("tooltip.devices"), value = `{online}/{#targets}` })

  barWidget.setTooltip(rows)
  barWidget.render(ui.glyph({ name = "send", color = connected and "on_surface" or "error" }))
end

noctalia.state.watch("taildrop.doc", function(value)
  doc = value
  render()
end)

noctalia.state.watch("taildrop.connected", function(value)
  connected = value == true
  render()
end)

noctalia.state.watch("taildrop.targets", function(value)
  targets = value or {}
  render()
end)

function onClick()
  noctalia.togglePanel("matt/taildrop:panel")
end

function update()
  render()
end
