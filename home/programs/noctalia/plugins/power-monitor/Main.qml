import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property int intervalSeconds: cfg.intervalSeconds ?? defaults.intervalSeconds ?? 2
  readonly property real thresholdGoodW: cfg.thresholdGoodW  ?? defaults.thresholdGoodW  ?? 8
  readonly property real thresholdWarnW: cfg.thresholdWarnW  ?? defaults.thresholdWarnW  ?? 15
  readonly property string colorGood:    cfg.colorGood       ?? defaults.colorGood       ?? "#A7C080"
  readonly property string colorWarning: cfg.colorWarning    ?? defaults.colorWarning    ?? "#DBBC7F"
  readonly property string colorCritical:cfg.colorCritical   ?? defaults.colorCritical   ?? "#E67E80"

  // Latest snapshot from the sampler.
  property var snapshot: ({ "ts": 0, "battery": { "present": false } })

  readonly property bool batteryPresent: snapshot?.battery?.present === true
  readonly property string batteryStatus: snapshot?.battery?.status ?? "Unknown"
  readonly property bool isDischarging: batteryStatus === "Discharging"
  readonly property real systemPowerW: (snapshot?.battery?.power_w ?? 0)
  readonly property int batteryPct: snapshot?.battery?.capacity ?? 0

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
    environment: ({ "INTERVAL": String(root.intervalSeconds) })
    running: true

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function (line) {
        if (!line || line[0] !== "{") return;
        try {
          root.snapshot = JSON.parse(line);
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

  // Restart the sampler when the interval changes so the new env takes effect.
  onIntervalSecondsChanged: {
    Logger.i("PowerMonitor", "Restarting sampler (cfg changed)");
    sampler.running = false;
    Qt.callLater(() => sampler.running = true);
  }
}
