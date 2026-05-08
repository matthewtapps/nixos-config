#!/usr/bin/env bash
# Power monitor sampler — emits one JSON line per tick on stdout.
#
# Driven by the Noctalia power-monitor QML plugin.
#
# Env knobs:
#   INTERVAL  sample period in seconds (default 2)
#   TOPN      how many processes to fully populate per tick (default 25)
#
# Notes on attribution:
#   - "system_power_w" is /sys/class/power_supply/BAT*/power_now in W. It is
#     only meaningful while Discharging; while charging or unplugged-but-full
#     it can read 0 or be the charge rate.
#   - "power_w" per process is total system_power_w pro-rated by CPU jiffies
#     used in this tick. CPU-only attribution; GPU/disk/wifi power is NOT
#     modeled. The QML side surfaces this caveat.

set -u

INTERVAL="${INTERVAL:-2}"
TOPN="${TOPN:-25}"
PAGESIZE_BYTES="$(getconf PAGESIZE)"
JIFFY="$(getconf CLK_TCK)"

exec gawk \
  -v interval="$INTERVAL" \
  -v topn="$TOPN" \
  -v pagesize="$PAGESIZE_BYTES" \
  -v jiffy="$JIFFY" '
function json_esc(s,    r) {
  r = s
  gsub(/\\/, "\\\\", r)
  gsub(/"/,  "\\\"", r)
  gsub(/\n/, "\\n",  r)
  gsub(/\r/, "\\r",  r)
  gsub(/\t/, "\\t",  r)
  return r
}

# Read /proc/stat first line, return total jiffies (sum of all CPU columns).
function read_proc_stat(    line, parts, n, i, total) {
  total = 0
  if ((getline line < "/proc/stat") > 0) {
    n = split(line, parts, " ")
    for (i = 2; i <= n; i++) total += parts[i] + 0
  }
  close("/proc/stat")
  return total
}

# Read total context switches from /proc/stat.
function read_ctxt(    line) {
  while ((getline line < "/proc/stat") > 0) {
    if (line ~ /^ctxt /) {
      close("/proc/stat")
      split(line, p, " ")
      return p[2] + 0
    }
  }
  close("/proc/stat")
  return 0
}

# Read /sys/class/power_supply/BAT*/uevent into bat[] keys.
# Returns 1 if any battery seen.
function read_battery(bat,    cmd, path, line, eq, k, v, found) {
  found = 0
  cmd = "ls -d /sys/class/power_supply/BAT* 2>/dev/null"
  while ((cmd | getline path) > 0) {
    while ((getline line < (path "/uevent")) > 0) {
      eq = index(line, "=")
      if (eq <= 0) continue
      k = substr(line, 1, eq - 1)
      v = substr(line, eq + 1)
      bat[k] = v
    }
    close(path "/uevent")
    found = 1
    break
  }
  close(cmd)
  return found
}

# Read /proc/meminfo into mem[] (kB units).
function read_meminfo(mem,    line, k, v) {
  while ((getline line < "/proc/meminfo") > 0) {
    if (split(line, p, /[ :]+/) >= 2) {
      mem[p[1]] = p[2] + 0
    }
  }
  close("/proc/meminfo")
}

# Read /proc/loadavg, fill load[1..3].
function read_loadavg(load,    line) {
  if ((getline line < "/proc/loadavg") > 0) {
    split(line, p, " ")
    load[1] = p[1] + 0
    load[2] = p[2] + 0
    load[3] = p[3] + 0
  }
  close("/proc/loadavg")
}

# Read CPU package temperature in millideg C from coretemp hwmon.
# Returns -1 if unavailable.
function read_pkg_temp(    cmd, p, line, t) {
  cmd = "cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null"
  t = -1
  while ((cmd | getline line) > 0) {
    if (line + 0 > 0 && (t < 0 || line + 0 < t)) t = line + 0
  }
  close(cmd)
  return t
}

# Walk /proc to harvest per-process snapshots.
# Fills:
#   t_jif[pid]    -> utime+stime jiffies (cumulative)
#   comm[pid]     -> short comm
#   rss_b[pid]    -> resident set bytes
#   nthr[pid]     -> threads
#   uid[pid]      -> real uid (-1 if unknown)
#   io_r[pid]     -> cumulative read_bytes
#   io_w[pid]     -> cumulative write_bytes
#   vol[pid]      -> voluntary ctxt switches (cumulative; proxy for wakeups)
#   nvol[pid]     -> nonvoluntary ctxt switches (cumulative)
function read_all_procs(t_jif, comm, rss_b, nthr, uid, io_r, io_w, vol, nvol,
                       cmd, f, pid, statpath, line, rpar, i, c, rest, parts,
                       iopath, ioline, sp, sl, statspath, k) {
  cmd = "ls /proc 2>/dev/null"
  while ((cmd | getline f) > 0) {
    if (f !~ /^[0-9]+$/) continue
    pid = f
    statpath = "/proc/" pid "/stat"
    if ((getline line < statpath) <= 0) { close(statpath); continue }
    close(statpath)

    # /proc/<pid>/stat is "<pid> (<comm>) <state> <fields...>". `comm` may
    # contain spaces and parens, so anchor on first `(` and last `)`.
    lpar = index(line, "(")
    rpar = 0
    for (i = length(line); i > 0; i--) {
      if (substr(line, i, 1) == ")") { rpar = i; break }
    }
    if (lpar < 1 || rpar <= lpar) continue
    c = substr(line, lpar + 1, rpar - lpar - 1)
    rest = substr(line, rpar + 2)
    # rest fields (1-indexed) map to original fields - 2:
    #   1=state 12=utime 13=stime 18=num_threads 22=rss(pages)
    if (split(rest, parts, " ") < 22) continue

    t_jif[pid] = parts[12] + parts[13]
    comm[pid]  = c
    rss_b[pid] = parts[22] * pagesize
    nthr[pid]  = parts[18] + 0

    # /proc/<pid>/io may be EACCES for other users; ignore failures.
    iopath = "/proc/" pid "/io"
    rr = -1; ww = -1
    while ((getline ioline < iopath) > 0) {
      if      (ioline ~ /^read_bytes:/)  { split(ioline, sp, " "); rr = sp[2] + 0 }
      else if (ioline ~ /^write_bytes:/) { split(ioline, sp, " "); ww = sp[2] + 0 }
    }
    close(iopath)
    io_r[pid] = rr
    io_w[pid] = ww

    # /proc/<pid>/status — Uid line and ctxt switches.
    statspath = "/proc/" pid "/status"
    uid[pid] = -1
    vol[pid] = -1
    nvol[pid] = -1
    while ((getline sl < statspath) > 0) {
      if      (sl ~ /^Uid:/) { split(sl, sp, /[ \t]+/); uid[pid] = sp[2] + 0 }
      else if (sl ~ /^voluntary_ctxt_switches:/)    { split(sl, sp, /[ \t]+/); vol[pid] = sp[2] + 0 }
      else if (sl ~ /^nonvoluntary_ctxt_switches:/) { split(sl, sp, /[ \t]+/); nvol[pid] = sp[2] + 0 }
    }
    close(statspath)
  }
  close(cmd)
}

# Resolve uid -> username via getpwuid (cached).
function uid_to_user(u,    cmd, name) {
  if (u < 0) return ""
  if (u in user_cache) return user_cache[u]
  cmd = "getent passwd " u " 2>/dev/null"
  if ((cmd | getline name) > 0) {
    split(name, sp, ":")
    user_cache[u] = sp[1]
  } else {
    user_cache[u] = u ""
  }
  close(cmd)
  return user_cache[u]
}

# Read the full command line; falls back to comm.
function read_cmdline(pid, fallback,    path, line) {
  path = "/proc/" pid "/cmdline"
  if ((getline line < path) > 0) {
    close(path)
    gsub(/\0/, " ", line)
    sub(/[ \t]+$/, "", line)
    if (length(line) > 0) return line
  }
  close(path)
  return "[" fallback "]"
}

# Numeric desc compare for arr[i] values.
function cmp_desc(arr, i, j) {
  if (arr[i] > arr[j]) return -1
  if (arr[i] < arr[j]) return 1
  return 0
}

# Selection-sort top N pids of "pids[]" by score in "score[]" desc.
# Picks the largest TOPN; result returned as top[1..n].
function pick_topn(pids, n_pids, score, want, top,    i, j, best, swap) {
  for (i = 1; i <= n_pids; i++) top[i] = pids[i]
  if (n_pids <= want) return n_pids
  # Partial selection sort: only need top "want" sorted.
  for (i = 1; i <= want && i <= n_pids; i++) {
    best = i
    for (j = i + 1; j <= n_pids; j++) {
      if (score[top[j]] > score[top[best]]) best = j
    }
    if (best != i) { swap = top[i]; top[i] = top[best]; top[best] = swap }
  }
  return want
}

BEGIN {
  if (interval + 0 < 1) interval = 1

  # --- initial seed ---
  read_all_procs(prev_t, prev_comm, prev_rss, prev_nthr, prev_uid,
                 prev_io_r, prev_io_w, prev_vol, prev_nvol)
  prev_total_jiffies = read_proc_stat()
  prev_ctxt = read_ctxt()
  prev_ts = systime()

  while (1) {
    system("sleep " interval)

    # --- collect ---
    delete cur_t; delete cur_comm; delete cur_rss; delete cur_nthr; delete cur_uid
    delete cur_io_r; delete cur_io_w; delete cur_vol; delete cur_nvol
    read_all_procs(cur_t, cur_comm, cur_rss, cur_nthr, cur_uid,
                   cur_io_r, cur_io_w, cur_vol, cur_nvol)
    cur_total_jiffies = read_proc_stat()
    cur_ctxt = read_ctxt()
    cur_ts = systime()
    elapsed = cur_ts - prev_ts
    if (elapsed < 1) elapsed = interval

    delete bat
    has_bat = read_battery(bat)

    delete mem
    read_meminfo(mem)

    delete load
    read_loadavg(load)

    pkg_temp_mC = read_pkg_temp()

    # --- system power ---
    system_power_w = 0
    has_power_now = 0
    if (has_bat && ("POWER_SUPPLY_POWER_NOW" in bat) && bat["POWER_SUPPLY_POWER_NOW"] != "") {
      system_power_w = (bat["POWER_SUPPLY_POWER_NOW"] + 0) / 1000000.0
      has_power_now = 1
    }
    is_discharging = (has_bat && bat["POWER_SUPPLY_STATUS"] == "Discharging")

    # --- per-process deltas ---
    delete pid_list; delete cpu_delta; delete iorate_r; delete iorate_w; delete vol_rate; delete nvol_rate
    n_pids = 0
    total_used_jiffies = 0
    for (pid in cur_t) {
      d = (pid in prev_t) ? (cur_t[pid] - prev_t[pid]) : cur_t[pid]
      if (d < 0) d = 0
      n_pids++
      pid_list[n_pids] = pid
      cpu_delta[pid] = d
      total_used_jiffies += d

      iorate_r[pid] = (pid in prev_io_r && prev_io_r[pid] >= 0 && cur_io_r[pid] >= 0) ? \
                      ((cur_io_r[pid] - prev_io_r[pid]) / elapsed) : 0
      iorate_w[pid] = (pid in prev_io_w && prev_io_w[pid] >= 0 && cur_io_w[pid] >= 0) ? \
                      ((cur_io_w[pid] - prev_io_w[pid]) / elapsed) : 0
      vol_rate[pid]  = (pid in prev_vol  && prev_vol[pid]  >= 0 && cur_vol[pid]  >= 0) ? \
                       ((cur_vol[pid] - prev_vol[pid]) / elapsed) : 0
      nvol_rate[pid] = (pid in prev_nvol && prev_nvol[pid] >= 0 && cur_nvol[pid] >= 0) ? \
                       ((cur_nvol[pid] - prev_nvol[pid]) / elapsed) : 0
    }

    # --- pick top N by CPU delta ---
    delete top
    n_top = pick_topn(pid_list, n_pids, cpu_delta, topn, top)

    # --- compute system-wide CPU% ---
    sys_jiffy_delta = cur_total_jiffies - prev_total_jiffies
    if (sys_jiffy_delta < 1) sys_jiffy_delta = 1
    sys_user_jiffies = total_used_jiffies
    sys_cpu_pct = (sys_user_jiffies / sys_jiffy_delta) * 100.0
    ctxt_per_sec = (cur_ctxt - prev_ctxt) / elapsed

    # --- emit JSON ---
    printf "{"
    printf "\"ts\":%d,\"interval\":%d,\"elapsed\":%.3f", cur_ts, interval, elapsed

    # battery
    if (has_bat) {
      printf ",\"battery\":{"
      printf "\"present\":true"
      if ("POWER_SUPPLY_STATUS" in bat) {
        printf ",\"status\":\"%s\"", json_esc(bat["POWER_SUPPLY_STATUS"])
      }
      if ("POWER_SUPPLY_CAPACITY" in bat)        printf ",\"capacity\":%d", bat["POWER_SUPPLY_CAPACITY"] + 0
      if ("POWER_SUPPLY_ENERGY_NOW" in bat)      printf ",\"energy_now_wh\":%.3f", bat["POWER_SUPPLY_ENERGY_NOW"] / 1000000.0
      if ("POWER_SUPPLY_ENERGY_FULL" in bat)     printf ",\"energy_full_wh\":%.3f", bat["POWER_SUPPLY_ENERGY_FULL"] / 1000000.0
      if ("POWER_SUPPLY_CYCLE_COUNT" in bat)     printf ",\"cycle_count\":%d", bat["POWER_SUPPLY_CYCLE_COUNT"] + 0
      if (has_power_now)                         printf ",\"power_w\":%.3f", system_power_w
      printf "}"
    } else {
      printf ",\"battery\":{\"present\":false}"
    }

    # cpu
    printf ",\"cpu\":{\"pct\":%.2f,\"ctxt_per_sec\":%.0f,\"load1\":%.2f,\"load5\":%.2f,\"load15\":%.2f", \
      sys_cpu_pct, ctxt_per_sec, load[1], load[2], load[3]
    if (pkg_temp_mC > 0) printf ",\"temp_c\":%.1f", pkg_temp_mC / 1000.0
    printf "}"

    # mem (MiB)
    printf ",\"mem\":{\"total\":%d,\"avail\":%d,\"used\":%d,\"swap_total\":%d,\"swap_used\":%d}", \
      mem["MemTotal"] / 1024, mem["MemAvailable"] / 1024, \
      (mem["MemTotal"] - mem["MemAvailable"]) / 1024, \
      mem["SwapTotal"] / 1024, (mem["SwapTotal"] - mem["SwapFree"]) / 1024

    # processes
    printf ",\"procs\":["
    for (i = 1; i <= n_top; i++) {
      pid = top[i]
      d = cpu_delta[pid]
      cpu_pct = (d / (elapsed * jiffy)) * 100.0
      share = (sys_user_jiffies > 0) ? (d / sys_user_jiffies) : 0
      pw = (is_discharging && has_power_now) ? (system_power_w * share) : 0
      uname = uid_to_user(cur_uid[pid])
      cmdline = read_cmdline(pid, cur_comm[pid])
      if (i > 1) printf ","
      printf "{"
      printf "\"pid\":%d", pid
      printf ",\"comm\":\"%s\"",    json_esc(cur_comm[pid])
      printf ",\"cmdline\":\"%s\"", json_esc(cmdline)
      printf ",\"user\":\"%s\"",    json_esc(uname)
      printf ",\"cpu_pct\":%.2f",   cpu_pct
      printf ",\"share\":%.4f",     share
      printf ",\"power_w\":%.3f",   pw
      printf ",\"rss_mb\":%.1f",    cur_rss[pid] / 1048576.0
      printf ",\"threads\":%d",     cur_nthr[pid]
      printf ",\"vol_per_sec\":%.1f",  vol_rate[pid]
      printf ",\"nvol_per_sec\":%.1f", nvol_rate[pid]
      printf ",\"read_kbps\":%.1f",  iorate_r[pid] / 1024.0
      printf ",\"write_kbps\":%.1f", iorate_w[pid] / 1024.0
      printf "}"
    }
    printf "]"
    printf "}\n"
    fflush()

    # --- rotate ---
    delete prev_t; delete prev_comm; delete prev_rss; delete prev_nthr; delete prev_uid
    delete prev_io_r; delete prev_io_w; delete prev_vol; delete prev_nvol
    for (pid in cur_t)     prev_t[pid]     = cur_t[pid]
    for (pid in cur_comm)  prev_comm[pid]  = cur_comm[pid]
    for (pid in cur_rss)   prev_rss[pid]   = cur_rss[pid]
    for (pid in cur_nthr)  prev_nthr[pid]  = cur_nthr[pid]
    for (pid in cur_uid)   prev_uid[pid]   = cur_uid[pid]
    for (pid in cur_io_r)  prev_io_r[pid]  = cur_io_r[pid]
    for (pid in cur_io_w)  prev_io_w[pid]  = cur_io_w[pid]
    for (pid in cur_vol)   prev_vol[pid]   = cur_vol[pid]
    for (pid in cur_nvol)  prev_nvol[pid]  = cur_nvol[pid]
    prev_total_jiffies = cur_total_jiffies
    prev_ctxt = cur_ctxt
    prev_ts = cur_ts
  }
}
'
