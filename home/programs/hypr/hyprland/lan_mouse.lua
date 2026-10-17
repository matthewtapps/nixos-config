local M = {}

local function readFile(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local text = file:read("a")
  file:close()
  return text
end

function M.pickTarget(lastText, targetsText)
  local targets = {}
  for side, peer in (targetsText or ""):gmatch("(%a+) ([%w%-]+)") do
    table.insert(targets, { side = side, peer = peer })
  end
  local last = lastText and lastText:match("^%s*([%w%-]+)")
  for _, target in ipairs(targets) do
    if target.peer == last then
      return target
    end
  end
  return targets[1]
end

local function outer(m, side)
  if side == "right" then
    return m.x + m.w
  elseif side == "left" then
    return -m.x
  elseif side == "bottom" then
    return m.y + m.h
  end
  return -m.y
end

-- Lan Mouse's layer-shell strip is 1 pixel wide, so the cursor must move onto
-- it from inside the monitor to register an enter.
function M.edgePoint(monitors, side)
  local best
  for _, m in ipairs(monitors) do
    if not best or outer(m, side) > outer(best, side) then
      best = m
    end
  end
  if not best then
    return nil
  end
  local midX = best.x + best.w // 2
  local midY = best.y + best.h // 2
  if side == "right" then
    return { x = best.x + best.w - 3, y = midY }, { x = best.x + best.w - 1, y = midY }
  elseif side == "left" then
    return { x = best.x + 2, y = midY }, { x = best.x, y = midY }
  elseif side == "bottom" then
    return { x = midX, y = best.y + best.h - 3 }, { x = midX, y = best.y + best.h - 1 }
  end
  return { x = midX, y = best.y + 2 }, { x = midX, y = best.y }
end

function M.logical(monitor)
  local scale = monitor.scale > 0 and monitor.scale or 1
  local w = math.floor(monitor.size.width / scale + 0.5)
  local h = math.floor(monitor.size.height / scale + 0.5)
  if monitor.transform % 2 == 1 then
    w, h = h, w
  end
  return { x = monitor.position.x, y = monitor.position.y, w = w, h = h }
end

function M.push()
  local dir = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/lan-mouse"
  local target = M.pickTarget(readFile(dir .. "/last"), readFile(dir .. "/targets"))
  if not target then
    hl.notification.create({ text = "Lan Mouse: no peer to switch to", timeout = 3000 })
    return
  end
  local monitors = {}
  for _, monitor in ipairs(hl.get_monitors()) do
    table.insert(monitors, M.logical(monitor))
  end
  local approach, edge = M.edgePoint(monitors, target.side)
  if approach then
    hl.dispatch(hl.dsp.cursor.move(approach))
    hl.dispatch(hl.dsp.cursor.move(edge))
  end
end

return M
