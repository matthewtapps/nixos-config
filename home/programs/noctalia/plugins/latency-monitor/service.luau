--!nonstrict
-- Pings every configured host on an interval, keeps a rolling 65 minute sample
-- window, and publishes per-host averages plus the host the bar should show.

local WINDOW_SECONDS = 65 * 60
local SPARK_POINTS = 60
local STATUS_RANK = { unknown = 0, good = 1, warning = 2, critical = 3 }

local hosts = {}

local function trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- The address reaches ping through /bin/sh, so drop everything that is not a
-- hostname or IP character before it gets there.
local function sanitize(address)
  return (address:gsub("[^%w%.%:%-]", ""))
end

local function parseHosts()
  local built = {}
  for _, entry in ipairs(noctalia.getConfig("hosts") or {}) do
    local name, address = entry:match("^(.-)=(.*)$")
    if not name then
      name, address = entry, entry
    end
    address = sanitize(trim(address))
    name = trim(name)
    if address ~= "" then
      table.insert(built, {
        name = name ~= "" and name or address,
        address = address,
        samples = {},
        lastRtt = -1,
        timedOut = false,
      })
    end
  end
  return built
end

local function averageWithin(host, minutes)
  local cutoff = os.time() - minutes * 60
  local sum, count = 0, 0
  for _, sample in ipairs(host.samples) do
    if sample.ts >= cutoff then
      sum += sample.rtt
      count += 1
    end
  end
  if count == 0 then
    return -1
  end
  return sum / count
end

local function statusFor(rtt)
  if rtt < 0 then
    return "unknown"
  end
  if rtt < noctalia.getConfig("threshold_good") then
    return "good"
  end
  if rtt < noctalia.getConfig("threshold_warning") then
    return "warning"
  end
  return "critical"
end

local function hostStatus(host, avg10, avg30, avg60)
  if host.timedOut then
    return "critical"
  end
  if #host.samples == 0 then
    return "unknown"
  end
  if avg10 >= 0 then
    return statusFor(avg10)
  end
  if avg30 >= 0 then
    return statusFor(avg30)
  end
  return statusFor(avg60)
end

-- ui.graph wants values in 0..1, so scale against the window peak. The 1 ms
-- floor keeps an all-zero window from dividing by zero.
local function sparkline(host)
  local first = math.max(1, #host.samples - SPARK_POINTS + 1)
  local peak = 1
  for i = first, #host.samples do
    peak = math.max(peak, host.samples[i].rtt)
  end
  local values = {}
  for i = first, #host.samples do
    table.insert(values, host.samples[i].rtt / peak)
  end
  return values
end

local function commit(host, rtt)
  local now = os.time()
  local kept = {}
  for _, sample in ipairs(host.samples) do
    if sample.ts >= now - WINDOW_SECONDS then
      table.insert(kept, sample)
    end
  end
  table.insert(kept, { ts = now, rtt = rtt })
  host.samples = kept
  host.lastRtt = rtt
  host.timedOut = false
end

local function publish()
  local rows = {}
  local worst, worstRank = nil, -1

  for _, host in ipairs(hosts) do
    local avg10 = averageWithin(host, 10)
    local avg30 = averageWithin(host, 30)
    local avg60 = averageWithin(host, 60)
    local row = {
      name = host.name,
      address = host.address,
      last = host.lastRtt,
      timedOut = host.timedOut,
      avg10 = avg10,
      avg30 = avg30,
      avg60 = avg60,
      status = hostStatus(host, avg10, avg30, avg60),
      spark = sparkline(host),
    }
    table.insert(rows, row)

    local rank = STATUS_RANK[row.status] or 0
    if rank > worstRank then
      worst, worstRank = row, rank
    end
  end

  local display = worst
  local named = trim(noctalia.getConfig("bar_host") or "")
  if named ~= "" then
    for _, row in ipairs(rows) do
      if row.name == named then
        display = row
        break
      end
    end
  end

  noctalia.state.set("latency.hosts", rows)
  noctalia.state.set("latency.display", display)
end

local function poll(host)
  local timeout = math.max(1, noctalia.getConfig("interval_seconds") - 1)
  noctalia.runAsync(`ping -n -c 1 -W {timeout} {host.address}`, function(result)
    local rtt = result.stdout and result.stdout:match("time[=<]([%d%.]+)")
    if result.exitCode == 0 and rtt then
      commit(host, math.round(tonumber(rtt)))
    else
      host.timedOut = true
      host.lastRtt = -1
    end
    publish()
  end)
end

function update()
  for _, host in ipairs(hosts) do
    poll(host)
  end
end

function onConfigChanged()
  hosts = parseHosts()
  noctalia.setUpdateInterval(math.max(1, noctalia.getConfig("interval_seconds")) * 1000)
  publish()
  update()
end

onConfigChanged()
