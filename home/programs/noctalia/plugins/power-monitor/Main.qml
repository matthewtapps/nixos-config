import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property int intervalSeconds: cfg.intervalSeconds ?? defaults.intervalSeconds ?? 2
  readonly property int topProcesses:    cfg.topProcesses    ?? defaults.topProcesses    ?? 25
  readonly property int historySamples:  cfg.historySamples  ?? defaults.historySamples  ?? 120
  readonly property real thresholdGoodW: cfg.thresholdGoodW  ?? defaults.thresholdGoodW  ?? 8
  readonly property real thresholdWarnW: cfg.thresholdWarnW  ?? defaults.thresholdWarnW  ?? 15
  readonly property string colorGood:    cfg.colorGood       ?? defaults.colorGood       ?? "#A7C080"
  readonly property string colorWarning: cfg.colorWarning    ?? defaults.colorWarning    ?? "#DBBC7F"
  readonly property string colorCritical:cfg.colorCritical   ?? defaults.colorCritical   ?? "#E67E80"
  readonly property bool showSparkline:  cfg.showSparkline   ?? defaults.showSparkline   ?? true
  readonly property string barShows:     cfg.barShows        ?? defaults.barShows        ?? "power_w"
  readonly property string defaultSort:  cfg.defaultSort     ?? defaults.defaultSort     ?? "power_w"

  // Latest snapshot from the sampler.
  property var snapshot: ({
    "ts": 0,
    "battery": { "present": false },
    "cpu": { "pct": 0, "load1": 0, "load5": 0, "load15": 0, "ctxt_per_sec": 0, "temp_c": -1 },
    "mem": { "total": 0, "avail": 0, "used": 0, "swap_total": 0, "swap_used": 0 },
    "procs": []
  })

  // Rolling history of total system power (W) for the sparkline.
  property var powerHistory: []

  readonly property bool batteryPresent: snapshot?.battery?.present === true
  readonly property string batteryStatus: snapshot?.battery?.status ?? "Unknown"
  readonly property bool isDischarging: batteryStatus === "Discharging"
  readonly property real systemPowerW: (snapshot?.battery?.power_w ?? 0)
  readonly property int batteryPct: snapshot?.battery?.capacity ?? 0
  readonly property real energyNowWh: snapshot?.battery?.energy_now_wh ?? 0
  readonly property real energyFullWh: snapshot?.battery?.energy_full_wh ?? 0
  readonly property int cycleCount: snapshot?.battery?.cycle_count ?? 0

  // Time-to-empty (minutes) when discharging; -1 otherwise.
  readonly property int timeToEmptyMin: {
    if (!isDischarging || systemPowerW <= 0.1 || energyNowWh <= 0)
      return -1;
    return Math.round((energyNowWh / systemPowerW) * 60);
  }
  // Time-to-full (minutes) when charging — needs a charge rate; we lack it,
  // so just expose 0/-1 for now.
  readonly property int timeToFullMin: -1

  readonly property real cpuPct:        snapshot?.cpu?.pct ?? 0
  readonly property real load1:         snapshot?.cpu?.load1 ?? 0
  readonly property real load5:         snapshot?.cpu?.load5 ?? 0
  readonly property real load15:        snapshot?.cpu?.load15 ?? 0
  readonly property int  ctxtPerSec:    snapshot?.cpu?.ctxt_per_sec ?? 0
  readonly property real cpuTempC:      snapshot?.cpu?.temp_c ?? -1

  readonly property int  memTotalMb:    snapshot?.mem?.total ?? 0
  readonly property int  memUsedMb:     snapshot?.mem?.used ?? 0
  readonly property int  memAvailMb:    snapshot?.mem?.avail ?? 0
  readonly property int  swapTotalMb:   snapshot?.mem?.swap_total ?? 0
  readonly property int  swapUsedMb:    snapshot?.mem?.swap_used ?? 0
  readonly property real memPct:        memTotalMb > 0 ? ((memUsedMb / memTotalMb) * 100) : 0

  readonly property var processes: snapshot?.procs ?? []

  readonly property string status: {
    if (!batteryPresent || !isDischarging) return "neutral";
    if (systemPowerW <= 0)                 return "neutral";
    if (systemPowerW < thresholdGoodW)     return "good";
    if (systemPowerW < thresholdWarnW)     return "warning";
    return "critical";
  }

  readonly property color statusColor: {
    switch (status) {
    case "good":     return colorGood;
    case "warning":  return colorWarning;
    case "critical": return colorCritical;
    default:         return Color.mOnSurface;
    }
  }

  signal sampleArrived

  function _pushHistory(w) {
    const arr = powerHistory.slice();
    arr.push(w);
    while (arr.length > historySamples) arr.shift();
    powerHistory = arr;
  }

  function killProcess(pid, hard) {
    const sig = hard ? "-KILL" : "-TERM";
    Logger.i("PowerMonitor", "kill", sig, pid);
    killProc.command = ["kill", sig, String(pid)];
    killProc.running = true;
  }

  // ---- sampler ----
  // The plugin lives at ~/.config/noctalia/plugins/power-monitor/. Resolve
  // sampler.sh relative to this Main.qml file so we don't hardcode a path.
  readonly property string samplerPath: {
    const u = Qt.resolvedUrl("sampler.sh").toString();
    return u.startsWith("file://") ? u.substring(7) : u;
  }

  Process {
    id: sampler
    command: ["bash", root.samplerPath]
    environment: ({
      "INTERVAL": String(root.intervalSeconds),
      "TOPN": String(root.topProcesses)
    })
    running: true

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function (line) {
        if (!line || line[0] !== "{") return;
        try {
          const snap = JSON.parse(line);
          root.snapshot = snap;
          if (snap.battery && snap.battery.power_w !== undefined) {
            root._pushHistory(snap.battery.power_w);
          } else {
            root._pushHistory(0);
          }
          root.sampleArrived();
        } catch (e) {
          Logger.e("PowerMonitor", "Bad sampler line:", e.toString());
        }
      }
    }

    stderr: SplitParser {
      splitMarker: "\n"
      onRead: function (line) {
        if (line && line.length > 0)
          Logger.w("PowerMonitor", "sampler:", line);
      }
    }

    onExited: function (code, status) {
      Logger.w("PowerMonitor", "sampler exited code=", code, " — restarting in 3s");
      restartTimer.start();
    }
  }

  Timer {
    id: restartTimer
    interval: 3000
    repeat: false
    onTriggered: sampler.running = true
  }

  Process {
    id: killProc
    running: false
  }

  // Restart the sampler when interval/topn change so the new env takes effect.
  property int _samplerRestartGen: 0
  onIntervalSecondsChanged: _restartSampler()
  onTopProcessesChanged: _restartSampler()
  function _restartSampler() {
    Logger.i("PowerMonitor", "Restarting sampler (cfg changed)");
    sampler.running = false;
    Qt.callLater(() => sampler.running = true);
  }
}
