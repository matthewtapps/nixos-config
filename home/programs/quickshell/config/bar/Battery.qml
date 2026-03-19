import QtQuick
import Quickshell.Services.UPower

// Mirrors waybar battery module with charging/level icons.
Text {
    readonly property var device: UPower.displayDevice
    readonly property double pct: device?.percentage ?? 0
    readonly property bool charging: !UPower.onBattery

    readonly property string icon: {
        if (charging) return "󰂄"
        if (pct >= 90) return ""
        if (pct >= 70) return ""
        if (pct >= 50) return ""
        if (pct >= 20) return ""
        return ""
    }

    text: icon + "  "
    color: pct <= 15 ? "#E67E80"
         : pct <= 30 ? "#DBBC7F"
         : "#D3C6AA"
    font.family: "GeistMono Nerd Font"
    font.pixelSize: 13
    verticalAlignment: Text.AlignVCenter

    // Hide on desktop systems with no battery
    visible: UPower.onBattery || (device !== null && device.percentage > 0)
}
