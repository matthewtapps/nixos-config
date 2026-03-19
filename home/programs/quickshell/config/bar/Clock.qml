import QtQuick
import Quickshell

// Mirrors waybar clock: HH:MM:SS  Day Mon DD
Text {
    readonly property SystemClock clock: SystemClock {
        precision: SystemClock.Seconds
    }

    text: Qt.formatDateTime(clock.date, "hh:mm:ss  ddd MMM dd")
    color: "#D3C6AA"
    font.family: "GeistMono Nerd Font"
    font.pixelSize: 13
    verticalAlignment: Text.AlignVCenter
}
