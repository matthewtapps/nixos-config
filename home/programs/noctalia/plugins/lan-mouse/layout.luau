--!nonstrict
local Layout = {}

local OPPOSITE = { left = "right", right = "left", top = "bottom", bottom = "top" }

Layout.FALLBACK_ORDER = { "right", "bottom", "left", "top" }

local function pairKey(a, b)
  return a < b and `{a}|{b}` or `{b}|{a}`
end

local function copyMap(t)
  local out = {}
  for k, v in pairs(type(t) == "table" and t or {}) do
    out[k] = v
  end
  return out
end

function Layout.normalise(doc)
  doc = type(doc) == "table" and doc or {}
  local links, seen = {}, {}
  for _, link in ipairs(type(doc.links) == "table" and doc.links or {}) do
    if
      type(link) == "table"
      and type(link.host) == "string"
      and type(link.peer) == "string"
      and link.host ~= link.peer
      and OPPOSITE[link.side]
      and not seen[pairKey(link.host, link.peer)]
    then
      seen[pairKey(link.host, link.peer)] = true
      table.insert(links, { host = link.host, peer = link.peer, side = link.side })
    end
  end
  return { enabled = copyMap(doc.enabled), links = links, monitors = copyMap(doc.monitors) }
end

function Layout.isEnabled(doc, host)
  return doc.enabled[host] ~= false
end

function Layout.sideOf(doc, me, peer)
  for _, link in ipairs(doc.links) do
    if link.host == me and link.peer == peer then
      return link.side
    elseif link.host == peer and link.peer == me then
      return OPPOSITE[link.side]
    end
  end
  return nil
end

local function otherEnd(link, me)
  if link.host == me then
    return link.peer
  elseif link.peer == me then
    return link.host
  end
  return nil
end

function Layout.view(doc, me, known)
  local view, taken = {}, {}
  if not Layout.isEnabled(doc, me) then
    return view
  end
  -- Lan Mouse deactivates one of 2 clients on a side, so a second is dropped.
  for _, link in ipairs(doc.links) do
    local peer = otherEnd(link, me)
    if peer and known[peer] and Layout.isEnabled(doc, peer) then
      local side = Layout.sideOf(doc, me, peer)
      if not taken[side] then
        taken[side] = true
        view[peer] = side
      end
    end
  end
  return view
end

local function withoutPair(links, a, b)
  local out = {}
  for _, link in ipairs(links) do
    if pairKey(link.host, link.peer) ~= pairKey(a, b) then
      table.insert(out, link)
    end
  end
  return out
end

function Layout.place(doc, me, peer, side)
  local next = Layout.normalise(doc)
  local previous = Layout.sideOf(next, me, peer)
  local occupant = nil
  if side then
    for _, link in ipairs(next.links) do
      local other = otherEnd(link, me)
      if other and other ~= peer and Layout.sideOf(next, me, other) == side then
        occupant = other
      end
    end
  end
  next.links = withoutPair(next.links, me, peer)
  if side then
    for _, link in ipairs(next.links) do
      local other = otherEnd(link, peer)
      if other and Layout.sideOf(next, peer, other) == OPPOSITE[side] then
        next.links = withoutPair(next.links, peer, other)
        break
      end
    end
  end
  if occupant then
    next.links = withoutPair(next.links, me, occupant)
    if previous then
      table.insert(next.links, { host = me, peer = occupant, side = previous })
    end
  end
  if side then
    table.insert(next.links, { host = me, peer = peer, side = side })
  end
  return next
end

function Layout.setEnabled(doc, host, on)
  local next = Layout.normalise(doc)
  next.enabled[host] = on
  return next
end

function Layout.setMonitors(doc, host, monitors)
  local next = Layout.normalise(doc)
  next.monitors[host] = monitors
  return next
end

function Layout.sameMonitors(a, b)
  if type(a) ~= "table" or type(b) ~= "table" or #a ~= #b then
    return false
  end
  for i, m in ipairs(a) do
    local n = b[i]
    if m.name ~= n.name or m.x ~= n.x or m.y ~= n.y or m.w ~= n.w or m.h ~= n.h then
      return false
    end
  end
  return true
end

function Layout.logicalMonitors(raw)
  local out = {}
  for _, m in ipairs(type(raw) == "table" and raw or {}) do
    if not m.disabled then
      local scale = (m.scale or 0) > 0 and m.scale or 1
      local w = math.floor(m.width / scale + 0.5)
      local h = math.floor(m.height / scale + 0.5)
      if (m.transform or 0) % 2 == 1 then
        w, h = h, w
      end
      table.insert(out, { name = m.name, x = m.x, y = m.y, w = w, h = h })
    end
  end
  table.sort(out, function(a, b)
    return a.name < b.name
  end)
  return out
end

function Layout.parseList(stdout)
  local clients = {}
  for line in stdout:gmatch("[^\n]+") do
    local id, host, pos, active = line:match("^id (%d+): (.-):%d+ %((%a+)%) active: (%a+)")
    if id then
      table.insert(clients, { id = tonumber(id), host = host, pos = pos, active = active == "true" })
    end
  end
  return clients
end

function Layout.plan(view, clients, addresses, hookFor)
  local commands, seen = {}, {}
  for _, client in ipairs(clients) do
    local side = view[client.host]
    if not side or seen[client.host] then
      table.insert(commands, { "remove-client", tostring(client.id) })
    else
      seen[client.host] = true
      if client.pos ~= side then
        table.insert(commands, { "set-position", tostring(client.id), side })
      end
      if not client.active then
        table.insert(commands, { "activate", tostring(client.id) })
      end
    end
  end
  local missing = {}
  for peer in pairs(view) do
    if not seen[peer] then
      table.insert(missing, peer)
    end
  end
  table.sort(missing)
  for _, peer in ipairs(missing) do
    local command = { "add-client", "--hostname", peer, "--enter-hook", hookFor(peer) }
    if addresses[peer] then
      table.insert(command, "--ips")
      table.insert(command, addresses[peer])
    end
    table.insert(commands, command)
  end
  return commands
end

function Layout.targets(view, online)
  local lines = {}
  for _, side in ipairs(Layout.FALLBACK_ORDER) do
    for peer, peerSide in pairs(view) do
      if peerSide == side and online[peer] then
        table.insert(lines, `{side} {peer}`)
      end
    end
  end
  return lines
end

return Layout
