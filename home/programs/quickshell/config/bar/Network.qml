import QtQuick
import Quickshell
import Quickshell.Io

// Mirrors waybar network: wifi/ethernet/disconnected icons.
// Left-click → nm-connection-editor
Item {
    id: root
    height: parent.height
    width: netText.implicitWidth

    property bool isWifi: false
    property bool isEthernet: false
    property bool isConnected: false
    property string ifName: ""

    Process {
        running: true
        command: [
            "bash", "-c",
            "while true; do\n" +
            "    result=$(nmcli -t -f type,state,device dev 2>/dev/null | while IFS=: read -r type state dev; do\n" +
            "        if [ \"$state\" = \"connected\" ]; then\n" +
            "            echo \"$type:$dev\"\n" +
            "            break\n" +
            "        fi\n" +
            "    done)\n" +
            "    echo \"${result:-disconnected:}\"\n" +
            "    sleep 3\n" +
            "done"
        ]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(':')
                const type = parts[0]
                const dev  = parts[1] || ""
                root.isWifi     = type === "wifi"
                root.isEthernet = type === "ethernet"
                root.isConnected = root.isWifi || root.isEthernet
                root.ifName     = dev
            }
        }
    }

    Text {
        id: netText
        anchors.centerIn: parent

        text: {
            if (root.isWifi)     return "   "
            if (root.isEthernet) return root.ifName + " 󰈀   "
            return "⚠  "
        }
        color: root.isConnected ? "#D3C6AA" : "#E67E80"
        font.family: "GeistMono Nerd Font"
        font.pixelSize: 13
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["nm-connection-editor"])
    }
}
