--!nonstrict
-- Bridges the local taildrop-syncd over SSE and owns every outbound send, so a
-- transfer and its notification outlive the panel that started it.

local TICK_MS = 5000
local TARGET_REFRESH_TICKS = 6

local doc = nil
local connected = false
local stream = nil
local seenDownloads = nil
local ticks = 0
local lastRequest = 0

local function base()
  return `http://127.0.0.1:{noctalia.getConfig("syncd_port")}`
end

local function publish()
  noctalia.state.set("taildrop.doc", doc)
  noctalia.state.set("taildrop.connected", connected)
end

local function connect()
  if stream then
    stream.stop()
    stream = nil
  end

  stream = noctalia.httpStream({ url = `{base()}/events` }, function(line)
    -- Heartbeats arrive as ": keepalive" comments and carry no payload.
    local payload = line:match("^data: (.*)$")
    if not payload then
      return
    end
    local value = noctalia.json.decode(payload)
    if value then
      doc, connected = value, true
      publish()
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

local function refreshTargets()
  noctalia.runAsync({ noctalia.getConfig("tailscale_bin"), "file", "cp", "--targets" }, function(result)
    local targets = {}
    if result.exitCode == 0 then
      for line in (result.stdout or ""):gmatch("[^\n]+") do
        local address, name, note = line:match("^(%S+)%s+(%S+)%s*(.*)$")
        if address and name then
          table.insert(targets, { name = name, address = address, online = noctalia.string.trim(note) == "" })
        end
      end
    end
    noctalia.state.set("taildrop.targets", targets)
  end)
end

local function scanDownloads()
  local dir = noctalia.getConfig("download_dir")
  local names = noctalia.listDir(dir)
  if not names then
    return
  end

  local current = {}
  for _, name in ipairs(names) do
    current[name] = true
  end

  -- Without this guard every file already on disk notifies at startup.
  if seenDownloads then
    local arrived = {}
    for name in pairs(current) do
      if not seenDownloads[name] then
        table.insert(arrived, name)
      end
    end
    if #arrived > 0 and noctalia.getConfig("notify_on_receive") then
      table.sort(arrived)
      noctalia.notify(noctalia.trp("notify.received", #arrived, { count = #arrived }), table.concat(arrived, "\n"))
    end
  end
  seenDownloads = current
end

local function sendPaths(paths, target)
  local argv = { noctalia.getConfig("tailscale_bin"), "file", "cp" }
  for _, path in ipairs(paths) do
    table.insert(argv, path)
  end
  table.insert(argv, `{target}:`)

  local label = #paths == 1 and (paths[1]:match("[^/]+$") or paths[1]) or noctalia.trp("notify.files", #paths, { count = #paths })
  noctalia.runAsync(argv, function(result)
    if result.exitCode == 0 then
      noctalia.notify(noctalia.tr("notify.sent", { target = target }), label)
    else
      noctalia.notifyError(
        noctalia.tr("notify.send_failed", { target = target }),
        noctalia.string.trim(result.stderr or "") ~= "" and result.stderr or label
      )
    end
  end, 60000)
end

local function sendText(text, target)
  local dir = noctalia.pluginDataDir()
  if not dir then
    noctalia.notifyError(noctalia.tr("notify.send_failed", { target = target }), noctalia.tr("notify.no_data_dir"))
    return
  end

  -- runAsync has no stdin, so text reaches `file cp` as a real file.
  local path = `{dir}/note-{noctalia.formatTime("%Y%m%d-%H%M%S")}.txt`
  local ok, err = noctalia.writeFile(path, text)
  if not ok then
    noctalia.notifyError(noctalia.tr("notify.send_failed", { target = target }), err or "")
    return
  end
  sendPaths({ path }, target)
end

noctalia.state.watch("taildrop.request", function(request)
  if type(request) ~= "table" or type(request.nonce) ~= "number" or request.nonce <= lastRequest then
    return
  end
  lastRequest = request.nonce

  if request.kind == "paths" and request.target then
    sendPaths(request.paths or {}, request.target)
  elseif request.kind == "text" and request.target then
    sendText(request.text or "", request.target)
  elseif request.kind == "targets" then
    refreshTargets()
  end
end)

function onIpc(event)
  if event == "refresh" then
    refreshTargets()
  elseif event == "reconnect" then
    connect()
  end
end

function update()
  ticks += 1
  if not stream then
    connect()
  end
  scanDownloads()
  if ticks % TARGET_REFRESH_TICKS == 1 then
    refreshTargets()
  end
end

function onConfigChanged()
  seenDownloads = nil
  connect()
  refreshTargets()
end

function onExit()
  if stream then
    stream.stop()
  end
end

noctalia.setUpdateInterval(TICK_MS)
publish()
connect()
refreshTargets()
scanDownloads()
