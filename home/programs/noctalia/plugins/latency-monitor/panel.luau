--!nonstrict
-- Panel view: one card per host with a sparkline of recent round trips and the
-- 10 / 30 / 60 minute averages.

local rows = {}

local COLOR_KEYS = {
  good = "color_good",
  warning = "color_warning",
  critical = "color_critical",
}

local function statusColor(status)
  local key = COLOR_KEYS[status]
  if key then
    return noctalia.getConfig(key)
  end
  return "on_surface"
end

local function milliseconds(value)
  if not value or value < 0 then
    return "--"
  end
  return `{math.round(value)}ms`
end

local function average(labelKey, value)
  return ui.column({ gap = 2 }, {
    ui.label({ text = noctalia.tr(labelKey), fontSize = 11, color = "on_surface_variant" }),
    ui.label({ text = milliseconds(value), fontSize = 13, fontWeight = "bold" }),
  })
end

local function card(row)
  local color = statusColor(row.status)
  return ui.column({ gap = 8, padding = 10, fill = "surface_variant/0.4", radius = 8 }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.label({ text = row.name, fontWeight = "bold", color = color }),
      ui.spacer({ flexGrow = 1 }),
      ui.label({
        text = row.timedOut and noctalia.tr("ui.timed_out") or row.address,
        fontSize = 11,
        color = "on_surface_variant",
      }),
    }),
    ui.graph({
      values = row.spark,
      color = color,
      lineWidth = 2,
      fillOpacity = 0.25,
      height = 44,
    }),
    ui.row({ gap = 16 }, {
      average("ui.avg_10m", row.avg10),
      average("ui.avg_30m", row.avg30),
      average("ui.avg_60m", row.avg60),
    }),
  })
end

local function render()
  local children = {}
  for _, row in ipairs(rows) do
    table.insert(children, card(row))
  end
  if #children == 0 then
    table.insert(children, ui.label({ text = noctalia.tr("ui.no_hosts"), color = "on_surface_variant" }))
  end
  panel.render(ui.column({ gap = 10, padding = 14 }, children))
end

noctalia.state.watch("latency.hosts", function(value)
  rows = value or {}
  render()
end)

function onOpen()
  render()
end
