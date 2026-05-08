import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property bool batteryPresent: mainInstance?.batteryPresent ?? false
  readonly property bool isDischarging: mainInstance?.isDischarging ?? false
  readonly property real systemPowerW: mainInstance?.systemPowerW ?? 0
  readonly property int batteryPct: mainInstance?.batteryPct ?? 0
  readonly property int eta: mainInstance?.timeToEmptyMin ?? -1
  readonly property color statusColor: mainInstance?.statusColor ?? Color.mOnSurface
  readonly property string barShows: mainInstance?.barShows ?? "power_w"
  readonly property bool showSparkline: mainInstance?.showSparkline ?? true
  readonly property var history: mainInstance?.powerHistory ?? []

  readonly property string primaryText: {
    if (!batteryPresent) return "—";
    switch (barShows) {
    case "battery_pct": return batteryPct + "%";
    case "both":        return systemPowerW.toFixed(1) + "W " + batteryPct + "%";
    case "power_w":
    default:            return isDischarging ? systemPowerW.toFixed(1) + "W" : batteryPct + "%";
    }
  }

  readonly property string tooltipText: {
    if (!batteryPresent) return pluginApi?.tr("widget.tooltip.noBattery");
    let parts = [];
    if (isDischarging) {
      parts.push(pluginApi?.tr("widget.tooltip.discharging") + ": " + systemPowerW.toFixed(2) + " W");
      if (eta > 0) {
        const h = Math.floor(eta / 60), m = eta % 60;
        parts.push(pluginApi?.tr("widget.tooltip.eta") + ": " + (h > 0 ? h + "h " : "") + m + "m");
      }
    } else {
      parts.push(mainInstance?.batteryStatus ?? "?");
    }
    parts.push(pluginApi?.tr("widget.tooltip.battery") + ": " + batteryPct + "%");
    parts.push(pluginApi?.tr("widget.tooltip.cpu") + ": " + (mainInstance?.cpuPct ?? 0).toFixed(1) + "%");
    return parts.join("\n");
  }

  readonly property real labelWidth: labelText.implicitWidth
  readonly property real sparkWidth: showSparkline && !isVertical ? Style.baseWidgetSize * 1.2 : 0
  readonly property real contentWidth: {
    if (isVertical) return capsuleHeight;
    return Style.marginM + labelWidth + (sparkWidth > 0 ? Style.marginS + sparkWidth : 0) + Style.marginM;
  }
  readonly property real contentHeight: isVertical ? capsuleHeight * 2 : capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Rectangle {
    id: capsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    radius: Style.radiusL
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Behavior on color     { ColorAnimation { duration: Style.animationFast } }
    Behavior on border.color { ColorAnimation { duration: Style.animationFast } }

    RowLayout {
      anchors.fill: parent
      spacing: Style.marginS
      visible: !root.isVertical

      NText {
        id: labelText
        text: root.primaryText
        pointSize: root.barFontSize
        applyUiScale: false
        color: root.statusColor
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: Style.marginM
        Behavior on color { ColorAnimation { duration: 300 } }
      }

      NGraph {
        id: spark
        visible: root.showSparkline && root.history.length >= 2
        Layout.preferredWidth: root.sparkWidth
        Layout.preferredHeight: root.capsuleHeight * 0.65
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: Style.marginS
        values: root.history
        minValue: 0
        maxValue: Math.max(1, root.mainInstance?.thresholdWarnW ?? 15, ...root.history) * 1.1
        fill: true
        animateScale: false
        color: root.statusColor
      }
    }

    NText {
      anchors.centerIn: parent
      visible: root.isVertical
      text: root.batteryPresent ? (root.isDischarging
                                   ? root.systemPowerW.toFixed(1) + "W"
                                   : root.batteryPct + "%") : "—"
      pointSize: root.barFontSize * 0.85
      applyUiScale: false
      font.weight: Font.Medium
      color: root.statusColor
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton

      onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
          if (pluginApi) pluginApi.openPanel(root.screen, root);
        } else if (mouse.button === Qt.RightButton) {
          PanelService.showContextMenu(contextMenu, root, screen);
        }
      }

      onEntered: TooltipService.show(root, root.tooltipText, BarService.getTooltipDirection(root.screen?.name))
      onExited: TooltipService.hide()
    }
  }

  NPopupContextMenu {
    id: contextMenu
    model: [
      { "label": pluginApi?.tr("menu.openPanel"), "action": "open",     "icon": "activity" },
      { "label": pluginApi?.tr("menu.settings"),  "action": "settings", "icon": "settings" }
    ]
    onTriggered: function (action) {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "open") {
        pluginApi.openPanel(root.screen, root);
      } else if (action === "settings") {
        BarService.openPluginSettings(root.screen, pluginApi.manifest);
      }
    }
  }
}
