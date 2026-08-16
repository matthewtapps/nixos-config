--!nonstrict
-- Bar view of the latency service: one glyph plus the display host's 10 minute
-- average, tinted by status, with every host's windowed averages in the tooltip.

local display = nil
local hasTooltip = false

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

local function label()
  if not display then
    return "--"
  end
  if display.timedOut then
    return display.name
  end

  local value = display.avg10 >= 0 and display.avg10 or display.last
  local showName = noctalia.getConfig("show_host_name")
  if value < 0 then
    return showName and display.name or "..."
  end
  if showName then
    return `{display.name} {milliseconds(value)}`
  end
  return milliseconds(value)
end

local function render()
  local color = statusColor(display and display.status or "unknown")
  local container = barWidget.isVertical() and ui.column or ui.row
  barWidget.render(container({ gap = 6, align = "center" }, {
    ui.glyph({ name = "activity", color = color }),
    ui.label({ text = label(), color = color }),
  }))
end

noctalia.state.watch("latency.display", function(value)
  display = value
  render()
end)

noctalia.state.watch("latency.hosts", function(rows)
  local lines = {}
  for _, row in ipairs(rows or {}) do
    local value = row.timedOut and noctalia.tr("ui.timed_out")
      or `{milliseconds(row.avg10)} / {milliseconds(row.avg30)} / {milliseconds(row.avg60)}`
    table.insert(lines, { key = row.name, value = value })
  end

  if #lines > 0 then
    barWidget.setTooltip(lines)
    hasTooltip = true
  elseif hasTooltip then
    barWidget.clearTooltip()
    hasTooltip = false
  end
end)

function onClick()
  noctalia.togglePanel("matt/latency-monitor:panel")
end

function update()
  render()
end
