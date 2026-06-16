#!/usr/bin/env bash
# Power monitor sampler — emits one JSON line per tick on stdout.
#
# Trimmed to the essentials: total system power draw from the battery. No
# per-process /proc walking, no mem/load/temp — those were the expensive part.
#
# Env knobs:
#   INTERVAL  sample period in seconds (default 2)
#
# Notes:
#   - "power_w" is /sys/class/power_supply/BAT*/power_now in W. It is only
#     meaningful while Discharging; while charging/full it can read 0 or the
#     charge rate.

set -u

INTERVAL="${INTERVAL:-2}"

exec gawk -v interval="$INTERVAL" '
function json_esc(s,    r) {
  r = s
  gsub(/\\/, "\\\\", r)
  gsub(/"/,  "\\\"", r)
  return r
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

BEGIN {
  if (interval + 0 < 1) interval = 1

  while (1) {
    delete bat
    has_bat = read_battery(bat)
    ts = systime()

    system_power_w = 0
    has_power_now = 0
    if (has_bat && ("POWER_SUPPLY_POWER_NOW" in bat) && bat["POWER_SUPPLY_POWER_NOW"] != "") {
      system_power_w = (bat["POWER_SUPPLY_POWER_NOW"] + 0) / 1000000.0
      has_power_now = 1
    }

    printf "{\"ts\":%d", ts
    if (has_bat) {
      printf ",\"battery\":{\"present\":true"
      if ("POWER_SUPPLY_STATUS" in bat)   printf ",\"status\":\"%s\"", json_esc(bat["POWER_SUPPLY_STATUS"])
      if ("POWER_SUPPLY_CAPACITY" in bat) printf ",\"capacity\":%d", bat["POWER_SUPPLY_CAPACITY"] + 0
      if (has_power_now)                  printf ",\"power_w\":%.3f", system_power_w
      printf "}"
    } else {
      printf ",\"battery\":{\"present\":false}"
    }
    printf "}\n"
    fflush()

    system("sleep " interval)
  }
}
'
