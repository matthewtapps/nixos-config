import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Mirrors waybar pulseaudio: volume% icon mic-icon
// Left-click → pavucontrol, Right-click → toggle mute
Item {
    id: root
    height: parent.height
    width: audioText.implicitWidth

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)

    // Microphone mute state via pactl (no native quickshell API for source mute)
    property bool micMuted: false

    Process {
        running: true
        command: [
            "bash", "-c",
            `while true; do
                pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -c "yes" || echo 0
                sleep 2
            done`
        ]
        stdout: SplitParser {
            onRead: data => { root.micMuted = parseInt(data.trim()) > 0 }
        }
    }

    Text {
        id: audioText
        anchors.centerIn: parent

        readonly property string volIcon: {
            if (root.muted || root.volume === 0) return "󰝟"
            if (root.volume < 33) return ""
            if (root.volume < 66) return ""
            return ""
        }
        readonly property string micIcon: root.micMuted ? "  " : "  "

        text: root.volume + "% " + volIcon + " " + micIcon
        color: root.muted ? "#D699B6" : "#D3C6AA"
        font.family: "GeistMono Nerd Font"
        font.pixelSize: 13
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["pavucontrol"])
            } else if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
            }
        }
    }
}
