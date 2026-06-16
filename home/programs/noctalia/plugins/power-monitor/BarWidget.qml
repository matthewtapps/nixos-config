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
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property bool batteryPresent: mainInstance?.batteryPresent ?? false
  readonly property bool isDischarging: mainInstance?.isDischarging ?? false
  readonly property real systemPowerW: mainInstance?.systemPowerW ?? 0
  readonly property int batteryPct: mainInstance?.batteryPct ?? 0
  readonly property color statusColor: mainInstance?.statusColor ?? Color.mOnSurface

  // Bar shows total discharge power while on battery; battery % otherwise.
  readonly property string primaryText: {
    if (!batteryPresent) return "—";
    return isDischarging ? systemPowerW.toFixed(1) + "W" : batteryPct + "%";
  }

  readonly property string tooltipText: {
    if (!batteryPresent) return pluginApi?.tr("widget.tooltip.noBattery");
    if (isDischarging)
      return pluginApi?.tr("widget.tooltip.discharging") + ": " + systemPowerW.toFixed(2) + " W";
    return (mainInstance?.batteryStatus ?? "?") + " — " + batteryPct + "%";
  }

  readonly property real labelWidth: labelText.implicitWidth
  implicitWidth: Style.marginM + labelWidth + Style.marginM
  implicitHeight: capsuleHeight

  Rectangle {
    id: capsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.implicitWidth
    height: root.implicitHeight
    radius: Style.radiusL
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Behavior on color     { ColorAnimation { duration: Style.animationFast } }
    Behavior on border.color { ColorAnimation { duration: Style.animationFast } }

    NText {
      id: labelText
      anchors.centerIn: parent
      text: root.primaryText
      pointSize: root.barFontSize
      applyUiScale: false
      color: root.statusColor
      Behavior on color { ColorAnimation { duration: 300 } }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.RightButton

      onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
          PanelService.showContextMenu(contextMenu, root, screen);
      }

      onEntered: TooltipService.show(root, root.tooltipText, BarService.getTooltipDirection(root.screen?.name))
      onExited: TooltipService.hide()
    }
  }

  NPopupContextMenu {
    id: contextMenu
    model: [
      { "label": pluginApi?.tr("menu.settings"), "action": "settings", "icon": "settings" }
    ]
    onTriggered: function (action) {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "settings")
        BarService.openPluginSettings(root.screen, pluginApi.manifest);
    }
  }
}
