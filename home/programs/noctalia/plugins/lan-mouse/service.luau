--!nonstrict
local Layout = require("./layout")

local TICK_MS = 5000

local doc = nil
local me = nil
local online = {}
local addresses = {}
local connected = false
local cliOk = true
local stream = nil
local busy = false
local lastRequest = 0

local function base()
  return `http://127.0.0.1:{noctalia.getConfig("layoutd_port")}`
end

local function runtimeDir()
  return `{noctalia.getenv("XDG_RUNTIME_DIR") or "/tmp"}/lan-mouse`
end

local function known()
  local set = {}
  for _, host in ipairs(noctalia.getConfig("hosts") or {}) do
    set[host] = true
  end
  return set
end

local function publish()
  noctalia.state.set("lanmouse.doc", doc)
  noctalia.state.set("lanmouse.me", me)
  noctalia.state.set("lanmouse.online", online)
  noctalia.state.set("lanmouse.connected", connected)
  noctalia.state.set("lanmouse.cli_ok", cliOk)
end

-- layoutd stores the layout JSON as the text of a taildrop-syncd revision.
local function decodeRevision(revision)
  local text = type(revision) == "table" and revision.text or ""
  return Layout.normalise(text ~= "" and noctalia.json.decode(text) or {})
end

local function write(next)
  local body = noctalia.json.encode({ text = noctalia.json.encode(next) })
  if not body then
    return
  end
  doc = next
  publish()
  noctalia.http({ url = `{base()}/doc`, method = "POST", body = body }, function() end)
end

local function hookFor(peer)
  local dir = runtimeDir()
  return `mkdir -p '{dir}' && printf %s {peer} > '{dir}/last'`
end

local function runAll(commands, done)
  local i = 0
  local function step()
    i += 1
    local command = commands[i]
    if not command then
      done()
      return
    end
    local argv = { noctalia.getConfig("lan_mouse_bin"), "cli" }
    for _, part in ipairs(command) do
      table.insert(argv, part)
    end
    noctalia.runAsync(argv, function(result)
      if result.exitCode ~= 0 then
        cliOk = false
      end
      step()
    end, 5000)
  end
  step()
end

local reconcile

-- A new client has no id until the next list, so one immediate rerun gives it
-- its side; `again` stops a failing add from looping.
reconcile = function(again)
  -- Before layoutd answers every client looks stale and would be removed.
  if busy or not doc or not me then
    return
  end
  busy = true
  local view = Layout.view(doc, me, known())
  noctalia.mkdirAll(runtimeDir())
  noctalia.writeFile(`{runtimeDir()}/targets`, table.concat(Layout.targets(view, online), "\n"))
  noctalia.runAsync({ noctalia.getConfig("lan_mouse_bin"), "cli", "list" }, function(result)
    if result.exitCode ~= 0 then
      cliOk, busy = false, false
      publish()
      return
    end
    cliOk = true
    local commands = Layout.plan(view, Layout.parseList(result.stdout or ""), addresses, hookFor)
    runAll(commands, function()
      busy = false
      publish()
      for _, command in ipairs(commands) do
        if command[1] == "add-client" and not again then
          reconcile(true)
          return
        end
      end
    end)
  end, 5000)
end

local function refreshHealth()
  noctalia.http({ url = `{base()}/health` }, function(response)
    if not (response.ok and response.status == 200) then
      return
    end
    local health = noctalia.json.decode(response.body)
    if not health then
      return
    end
    me = health.origin
    online, addresses = {}, {}
    for _, peer in ipairs(health.peers or {}) do
      online[peer.host] = peer.online == true
      addresses[peer.host] = peer.address
    end
    if me then
      online[me] = true
    end
    publish()
  end)
end

local function publishMonitors()
  if not doc or not me then
    return
  end
  noctalia.runAsync({ "hyprctl", "monitors", "-j" }, function(result)
    if result.exitCode ~= 0 then
      return
    end
    local monitors = Layout.logicalMonitors(noctalia.json.decode(result.stdout or "") or {})
    if doc and not Layout.sameMonitors(doc.monitors[me], monitors) then
      write(Layout.setMonitors(doc, me, monitors))
    end
  end, 5000)
end

local function connect()
  if stream then
    stream.stop()
    stream = nil
  end
  stream = noctalia.httpStream({ url = `{base()}/events` }, function(line)
    local payload = line:match("^data: (.*)$")
    if not payload then
      return
    end
    local revision = noctalia.json.decode(payload)
    if revision then
      doc, connected = decodeRevision(revision), true
      publish()
      reconcile(false)
    end
  end, function()
    connected, stream = false, nil
    publish()
  end)
  if not stream then
    connected = false
    publish()
  end
end

noctalia.state.watch("lanmouse.request", function(request)
  if type(request) ~= "table" or type(request.nonce) ~= "number" or request.nonce <= lastRequest then
    return
  end
  lastRequest = request.nonce
  if not doc or not me then
    return
  end
  if request.kind == "place" and type(request.peer) == "string" then
    write(Layout.place(doc, me, request.peer, request.side))
  elseif request.kind == "enable" and type(request.host) == "string" then
    write(Layout.setEnabled(doc, request.host, request.on == true))
  end
  reconcile(false)
end)

function update()
  if not stream then
    connect()
  end
  refreshHealth()
  publishMonitors()
  reconcile(false)
end

function onConfigChanged()
  connect()
  refreshHealth()
end

function onExit()
  if stream then
    stream.stop()
  end
end

noctalia.setUpdateInterval(TICK_MS)
publish()
connect()
refreshHealth()
