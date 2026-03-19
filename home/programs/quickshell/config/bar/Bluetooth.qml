import QtQuick
import Quickshell
import Quickshell.Io

// Mirrors waybar bluetooth: enabled/disabled/connected icons.
// Left-click → overskride
Item {
    id: root
    height: parent.height
    width: btText.implicitWidth

    property bool btEnabled: false
    property bool btConnected: false

    Process {
        running: true
        command: [
            "bash", "-c",
            `while true; do
                if rfkill list bluetooth 2>/dev/null | grep -q "Soft blocked: yes"; then
                    echo disabled
                elif bluetoothctl info 2>/dev/null | grep -q "Connected: yes"; then
                    echo connected
                else
                    echo enabled
                fi
                sleep 3
            done`
        ]
        stdout: SplitParser {
            onRead: data => {
                const s = data.trim()
                root.btEnabled   = s !== "disabled"
                root.btConnected = s === "connected"
            }
        }
    }

    Text {
        id: btText
        anchors.centerIn: parent
        text: root.btConnected ? "󰂱  "
            : root.btEnabled   ? "  "
            : "󰂲  "
        color: "#D3C6AA"
        font.family: "GeistMono Nerd Font"
        font.pixelSize: 13
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["overskride"])
    }
}
