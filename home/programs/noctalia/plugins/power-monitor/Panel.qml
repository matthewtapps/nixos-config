import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 760 * Style.uiScaleRatio
  property real contentPreferredHeight: 720 * Style.uiScaleRatio
  readonly property bool allowAttach: true

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property var processes: mainInstance?.processes ?? []
  readonly property bool isDischarging: mainInstance?.isDischarging ?? false

  property string sortBy: mainInstance?.defaultSort ?? "power_w"
  property bool sortDesc: true
  property string searchText: ""
  property int killConfirmPid: -1
  property string killConfirmComm: ""

  function fmtWatts(w) { return w >= 0 ? w.toFixed(2) + " W" : "—"; }
  function fmtPct(p)   { return p.toFixed(1) + "%"; }
  function fmtMem(mb) {
    if (mb < 1024) return Math.round(mb) + " MB";
    return (mb / 1024).toFixed(1) + " GB";
  }
  function fmtRate(kbps) {
    if (kbps < 1) return "0";
    if (kbps < 1024) return kbps.toFixed(0) + " KB/s";
    return (kbps / 1024).toFixed(1) + " MB/s";
  }
  function fmtEta(min) {
    if (min < 0) return "—";
    if (min < 60) return min + " min";
    return Math.floor(min / 60) + "h " + (min % 60) + "m";
  }
  function fmtTemp(c) { return c >= 0 ? c.toFixed(0) + "°C" : "—"; }

  function displayName(p) {
    const cmd = (p.cmdline || "").trim();
    if (!cmd || cmd[0] === "[") return p.comm || "?";
    const arg0 = cmd.split(" ")[0];
    const slash = arg0.lastIndexOf("/");
    return slash >= 0 ? arg0.substring(slash + 1) : arg0;
  }

  function sorted() {
    const key = root.sortBy;
    const arr = processes.slice();
    arr.sort(function (a, b) {
      let av, bv;
      if (key === "name") {
        av = (root.displayName(a) || "").toLowerCase();
        bv = (root.displayName(b) || "").toLowerCase();
        if (av < bv) return -1;
        if (av > bv) return 1;
        return 0;
      } else if (key === "io") {
        av = (a.read_kbps || 0) + (a.write_kbps || 0);
        bv = (b.read_kbps || 0) + (b.write_kbps || 0);
      } else {
        av = a[key] ?? 0;
        bv = b[key] ?? 0;
      }
      return av - bv;
    });
    if (root.sortDesc) arr.reverse();
    if (root.searchText.length > 0) {
      const q = root.searchText.toLowerCase();
      return arr.filter(function (p) {
        return (p.comm || "").toLowerCase().indexOf(q) >= 0
            || (p.cmdline || "").toLowerCase().indexOf(q) >= 0
            || String(p.pid).indexOf(q) >= 0
            || (p.user || "").toLowerCase().indexOf(q) >= 0;
      });
    }
    return arr;
  }

  function setSort(key) {
    if (root.sortBy === key) {
      root.sortDesc = !root.sortDesc;
    } else {
      root.sortBy = key;
      root.sortDesc = (key !== "name");
    }
  }

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: "activity"
          pointSize: Style.fontSizeXL
          color: Color.mPrimary
          Layout.alignment: Qt.AlignVCenter
        }
        NText {
          text: pluginApi?.tr("panel.title") || "Power Monitor"
          pointSize: Style.fontSizeL
          font.weight: Font.Bold
          color: Color.mOnSurface
          Layout.alignment: Qt.AlignVCenter
        }
        Item { Layout.fillWidth: true }

        NIconButton {
          icon: "settings"
          tooltipText: pluginApi?.tr("menu.settings") || "Settings"
          onClicked: {
            const screen = pluginApi?.panelOpenScreen;
            if (screen) {
              pluginApi.closePanel(screen);
              Qt.callLater(() => BarService.openPluginSettings(screen, pluginApi.manifest));
            }
          }
          Layout.alignment: Qt.AlignVCenter
        }
        NIconButton {
          icon: "x"
          tooltipText: pluginApi?.tr("panel.close") || "Close"
          onClicked: {
            const s = pluginApi?.panelOpenScreen;
            if (s) pluginApi.closePanel(s);
          }
          Layout.alignment: Qt.AlignVCenter
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 4
        rowSpacing: Style.marginS
        columnSpacing: Style.marginS

        StatCard {
          label: pluginApi?.tr("panel.stat.power") || "Power"
          value: root.isDischarging ? root.fmtWatts(mainInstance?.systemPowerW ?? 0) : "—"
          subtitle: root.isDischarging
                    ? (pluginApi?.tr("panel.stat.discharging") || "Discharging")
                    : (mainInstance?.batteryStatus ?? "")
          accent: mainInstance?.statusColor ?? Color.mOnSurface
          Layout.fillWidth: true
        }
        StatCard {
          label: pluginApi?.tr("panel.stat.battery") || "Battery"
          value: (mainInstance?.batteryPct ?? 0) + "%"
          subtitle: {
            const wh = mainInstance?.energyNowWh ?? 0;
            const full = mainInstance?.energyFullWh ?? 0;
            return wh.toFixed(1) + " / " + full.toFixed(1) + " Wh";
          }
          accent: Color.mSecondary
          Layout.fillWidth: true
        }
        StatCard {
          label: pluginApi?.tr("panel.stat.eta") || "Time left"
          value: root.fmtEta(mainInstance?.timeToEmptyMin ?? -1)
          subtitle: (pluginApi?.tr("panel.stat.cycles") || "Cycles") + ": " + (mainInstance?.cycleCount ?? 0)
          accent: Color.mTertiary
          Layout.fillWidth: true
        }
        StatCard {
          label: pluginApi?.tr("panel.stat.cpu") || "CPU"
          value: root.fmtPct(mainInstance?.cpuPct ?? 0)
          subtitle: (pluginApi?.tr("panel.stat.load") || "load") + " " + (mainInstance?.load1 ?? 0).toFixed(2)
          accent: Color.mPrimary
          Layout.fillWidth: true
        }
        StatCard {
          label: pluginApi?.tr("panel.stat.memory") || "Memory"
          value: root.fmtPct(mainInstance?.memPct ?? 0)
          subtitle: root.fmtMem(mainInstance?.memUsedMb ?? 0) + " / " + root.fmtMem(mainInstance?.memTotalMb ?? 0)
          accent: Color.mSecondary
          Layout.fillWidth: true
        }
        StatCard {
          label: pluginApi?.tr("panel.stat.swap") || "Swap"
          value: (mainInstance?.swapTotalMb ?? 0) > 0
                 ? root.fmtPct(((mainInstance?.swapUsedMb ?? 0) / (mainInstance?.swapTotalMb ?? 1)) * 100)
                 : "—"
          subtitle: root.fmtMem(mainInstance?.swapUsedMb ?? 0) + " / " + root.fmtMem(mainInstance?.swapTotalMb ?? 0)
          accent: Color.mTertiary
          Layout.fillWidth: true
        }
        StatCard {
          label: pluginApi?.tr("panel.stat.ctxt") || "Context switches"
          value: (mainInstance?.ctxtPerSec ?? 0).toLocaleString(Qt.locale(), "f", 0) + "/s"
          subtitle: pluginApi?.tr("panel.stat.systemWide") || "system-wide"
          accent: Color.mPrimary
          Layout.fillWidth: true
        }
        StatCard {
          label: pluginApi?.tr("panel.stat.temp") || "Temp"
          value: root.fmtTemp(mainInstance?.cpuTempC ?? -1)
          subtitle: pluginApi?.tr("panel.stat.package") || "package"
          accent: Color.mTertiary
          Layout.fillWidth: true
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 90 * Style.uiScaleRatio

        NGraph {
          anchors.fill: parent
          values: mainInstance?.powerHistory ?? []
          minValue: 0
          maxValue: {
            const h = mainInstance?.powerHistory ?? [];
            const w = mainInstance?.thresholdWarnW ?? 15;
            const m = h.length > 0 ? Math.max(w, ...h) : w;
            return m * 1.15;
          }
          fill: true
          animateScale: false
          color: mainInstance?.statusColor ?? Color.mPrimary
        }

        NText {
          anchors {
            top: parent.top
            left: parent.left
            margins: Style.marginXS
          }
          text: pluginApi?.tr("panel.graph.title") || "System power (W)"
          pointSize: Style.fontSizeXS
          color: Qt.alpha(Color.mOnSurface, 0.55)
        }
      }

      NDivider { Layout.fillWidth: true; opacity: 0.4 }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NTextInput {
          Layout.fillWidth: true
          placeholderText: pluginApi?.tr("panel.search.placeholder") || "Filter…"
          text: root.searchText
          onTextChanged: root.searchText = text
        }

        NText {
          text: pluginApi?.tr("panel.caveat") || ""
          pointSize: Style.fontSizeXS
          color: Qt.alpha(Color.mOnSurfaceVariant, 0.8)
          Layout.maximumWidth: 280
          wrapMode: Text.WordWrap
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        SortHeader { Layout.preferredWidth: 60; textValue: "PID";                                         active: root.sortBy === "pid";        desc: root.sortDesc; onTrigger: root.setSort("pid") }
        SortHeader { Layout.fillWidth: true;    textValue: pluginApi?.tr("panel.col.name")  || "Process"; active: root.sortBy === "name";       desc: root.sortDesc; onTrigger: root.setSort("name") }
        SortHeader { Layout.preferredWidth: 50; textValue: pluginApi?.tr("panel.col.cpu")   || "CPU";     active: root.sortBy === "cpu_pct";    desc: root.sortDesc; onTrigger: root.setSort("cpu_pct") }
        SortHeader { Layout.preferredWidth: 60; textValue: pluginApi?.tr("panel.col.power") || "W";       active: root.sortBy === "power_w";    desc: root.sortDesc; onTrigger: root.setSort("power_w") }
        SortHeader { Layout.preferredWidth: 70; textValue: pluginApi?.tr("panel.col.rss")   || "RSS";     active: root.sortBy === "rss_mb";     desc: root.sortDesc; onTrigger: root.setSort("rss_mb") }
        SortHeader { Layout.preferredWidth: 70; textValue: pluginApi?.tr("panel.col.wakes") || "wakes/s"; active: root.sortBy === "vol_per_sec"; desc: root.sortDesc; onTrigger: root.setSort("vol_per_sec") }
        SortHeader { Layout.preferredWidth: 80; Layout.rightMargin: Style.marginS; textValue: pluginApi?.tr("panel.col.io") || "I/O"; active: root.sortBy === "io"; desc: root.sortDesc; onTrigger: root.setSort("io") }
        Item { Layout.preferredWidth: 22 }
      }

      NScrollView {
        id: procScroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        horizontalPolicy: ScrollBar.AlwaysOff

        ColumnLayout {
          width: procScroll.availableWidth
          spacing: Style.marginXXS

          Repeater {
            model: root.sorted()
            delegate: Rectangle {
              required property var modelData
              required property int index

              Layout.fillWidth: true
              implicitHeight: 36 * Style.uiScaleRatio
              radius: Style.radiusS
              color: index % 2 === 0 ? Qt.alpha(Color.mSurfaceVariant, 0.18) : "transparent"

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.marginS
                anchors.rightMargin: Style.marginS
                spacing: Style.marginS

                NText {
                  Layout.preferredWidth: 60
                  text: String(modelData.pid)
                  pointSize: Style.fontSizeXS
                  color: Qt.alpha(Color.mOnSurface, 0.7)
                }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  NText {
                    Layout.fillWidth: true
                    text: root.displayName(modelData)
                    pointSize: Style.fontSizeS
                    color: Color.mOnSurface
                    elide: Text.ElideRight
                  }
                  NText {
                    Layout.fillWidth: true
                    text: (modelData.user ? modelData.user + " · " : "") +
                          (modelData.cmdline || modelData.comm || "")
                    pointSize: Style.fontSizeXS
                    color: Qt.alpha(Color.mOnSurfaceVariant, 0.75)
                    elide: Text.ElideRight
                    visible: text.length > 0
                  }
                }
                NText {
                  Layout.preferredWidth: 50
                  horizontalAlignment: Text.AlignRight
                  text: (modelData.cpu_pct ?? 0).toFixed(1)
                  pointSize: Style.fontSizeS
                  color: (modelData.cpu_pct ?? 0) > 50 ? Color.mTertiary : Color.mOnSurface
                }
                NText {
                  Layout.preferredWidth: 60
                  horizontalAlignment: Text.AlignRight
                  text: root.isDischarging ? (modelData.power_w ?? 0).toFixed(2) : "—"
                  pointSize: Style.fontSizeS
                  color: {
                    const pw = modelData.power_w ?? 0;
                    if (!root.isDischarging) return Qt.alpha(Color.mOnSurface, 0.5);
                    const warn = mainInstance?.thresholdWarnW ?? 15;
                    const good = mainInstance?.thresholdGoodW ?? 8;
                    if (pw > warn / 4) return Color.mError;
                    if (pw > good / 4) return Color.mTertiary;
                    return Color.mOnSurface;
                  }
                }
                NText {
                  Layout.preferredWidth: 70
                  horizontalAlignment: Text.AlignRight
                  text: root.fmtMem(modelData.rss_mb ?? 0)
                  pointSize: Style.fontSizeS
                  color: Color.mOnSurface
                }
                NText {
                  Layout.preferredWidth: 70
                  horizontalAlignment: Text.AlignRight
                  text: Math.round(modelData.vol_per_sec ?? 0)
                  pointSize: Style.fontSizeS
                  color: (modelData.vol_per_sec ?? 0) > 200 ? Color.mTertiary : Color.mOnSurface
                }
                NText {
                  Layout.preferredWidth: 80
                  Layout.rightMargin: Style.marginS
                  horizontalAlignment: Text.AlignRight
                  text: {
                    const r = modelData.read_kbps ?? 0, w = modelData.write_kbps ?? 0;
                    if (r === 0 && w === 0) return "—";
                    return root.fmtRate(r + w);
                  }
                  pointSize: Style.fontSizeXS
                  color: Color.mOnSurface
                }
                NIconButton {
                  baseSize: 22
                  applyUiScale: false
                  Layout.alignment: Qt.AlignVCenter
                  icon: "x"
                  tooltipText: pluginApi?.tr("panel.kill.tooltip") || "Kill"
                  onClicked: {
                    root.killConfirmPid = modelData.pid;
                    root.killConfirmComm = root.displayName(modelData);
                    killDialog.shiftHeld = false;
                    killDialog.open();
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Popup {
    id: killDialog
    property bool shiftHeld: false
    modal: true
    focus: true
    width: 380
    height: confirmCol.implicitHeight + Style.marginL * 2
    anchors.centerIn: Overlay.overlay
    background: Rectangle {
      color: Color.mSurfaceVariant
      border.color: Color.mOutline
      border.width: 1
      radius: Style.radiusM
    }

    contentItem: ColumnLayout {
      id: confirmCol
      spacing: Style.marginM

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("panel.kill.title") || "End process?"
        pointSize: Style.fontSizeM
        font.weight: Font.Bold
        color: Color.mOnSurface
      }
      NText {
        Layout.fillWidth: true
        text: (pluginApi?.tr("panel.kill.body") || "Send signal to") + " " + root.killConfirmComm + " (PID " + root.killConfirmPid + ")?"
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
      }
      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("panel.kill.shiftHint") || ""
        pointSize: Style.fontSizeXS
        color: Qt.alpha(Color.mOnSurfaceVariant, 0.7)
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS
        Item { Layout.fillWidth: true }
        NButton {
          text: pluginApi?.tr("panel.kill.cancel") || "Cancel"
          onClicked: killDialog.close()
        }
        NButton {
          text: pluginApi?.tr("panel.kill.confirm") || "Confirm"
          onClicked: {
            mainInstance?.killProcess(root.killConfirmPid, killDialog.shiftHeld);
            killDialog.close();
          }
        }
      }
    }

    Keys.onPressed: function (e) {
      if (e.key === Qt.Key_Shift) killDialog.shiftHeld = true;
      else if (e.key === Qt.Key_Escape) killDialog.close();
      else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
        mainInstance?.killProcess(root.killConfirmPid, killDialog.shiftHeld);
        killDialog.close();
      }
    }
    Keys.onReleased: function (e) {
      if (e.key === Qt.Key_Shift) killDialog.shiftHeld = false;
    }
  }

  component StatCard: Rectangle {
    property string label: ""
    property string value: ""
    property string subtitle: ""
    property color accent: Color.mPrimary
    implicitHeight: 64 * Style.uiScaleRatio
    radius: Style.radiusS
    color: Qt.alpha(Color.mSurfaceVariant, 0.35)
    border.color: Qt.alpha(accent, 0.35)
    border.width: 1
    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginS
      spacing: 0
      NText {
        text: label
        pointSize: Style.fontSizeXS
        color: Qt.alpha(Color.mOnSurfaceVariant, 0.85)
      }
      NText {
        text: value
        pointSize: Style.fontSizeL
        font.weight: Font.Bold
        color: accent
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
      NText {
        text: subtitle
        pointSize: Style.fontSizeXS
        color: Qt.alpha(Color.mOnSurface, 0.6)
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }
  }

  component SortHeader: Rectangle {
    property string textValue: ""
    property bool active: false
    property bool desc: true
    signal trigger
    Layout.preferredHeight: 22
    implicitHeight: 22
    radius: Style.radiusXS
    color: active ? Qt.alpha(Color.mPrimary, 0.18) : "transparent"
    NText {
      anchors.centerIn: parent
      text: parent.textValue + (parent.active ? (parent.desc ? " ▾" : " ▴") : "")
      pointSize: Style.fontSizeXS
      font.weight: parent.active ? Font.Bold : Font.Medium
      color: parent.active ? Color.mPrimary : Qt.alpha(Color.mOnSurface, 0.7)
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: parent.trigger()
    }
  }
}
