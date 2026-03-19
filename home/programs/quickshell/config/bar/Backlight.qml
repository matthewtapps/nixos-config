import QtQuick
import Quickshell.Io

// Mirrors waybar backlight module. Reads from /sys/class/backlight/*.
Item {
    id: root
    height: parent.height
    width: backlightText.implicitWidth

    property int brightness: 0
    property int maxBrightness: 100
    readonly property int pct: maxBrightness > 0 ? Math.round(brightness * 100 / maxBrightness) : 0

    Process {
        running: true
        command: [
            "bash", "-c",
            `while true; do
                max=$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1)
                cur=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -1)
                [ -n "$max" ] && [ -n "$cur" ] && echo "$cur/$max"
                sleep 2
            done`
        ]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split('/')
                if (parts.length === 2) {
                    root.brightness = parseInt(parts[0]) || 0
                    root.maxBrightness = parseInt(parts[1]) || 100
                }
            }
        }
    }

    Text {
        id: backlightText
        anchors.centerIn: parent

        readonly property string icon: {
            const p = root.pct
            if (p >= 88) return ""
            if (p >= 75) return ""
            if (p >= 63) return ""
            if (p >= 50) return ""
            if (p >= 38) return ""
            if (p >= 25) return ""
            if (p >= 13) return ""
            if (p >= 1)  return ""
            return ""
        }

        text: icon + "  "
        color: "#D3C6AA"
        font.family: "GeistMono Nerd Font"
        font.pixelSize: 13

        // Hide if no backlight device (e.g. desktop)
        visible: root.maxBrightness > 0 && root.brightness > 0
    }
}
