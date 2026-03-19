import QtQuick
import Quickshell.Hyprland

// Mirrors waybar hyprland/workspaces with all-outputs: true
Row {
    required property var screen

    height: parent.height
    spacing: 0

    Repeater {
        model: Hyprland.workspaces

        delegate: Item {
            required property var modelData
            readonly property var ws: modelData

            // Only show numbered workspaces 1-9
            visible: ws.id > 0 && ws.id <= 9
            width: visible ? wsLabel.implicitWidth : 0
            height: parent.height

            Text {
                id: wsLabel
                anchors.centerIn: parent
                text: ws.id
                color: Hyprland.focusedWorkspace?.id === ws.id ? "#A7C080" : "#D3C6AA"
                font.family: "GeistMono Nerd Font"
                font.pixelSize: 13
                leftPadding: 8
                rightPadding: 8
            }

            MouseArea {
                anchors.fill: parent
                onClicked: ws.activate()
                hoverEnabled: true
                onEntered: wsLabel.opacity = 0.7
                onExited: wsLabel.opacity = 1.0
            }
        }
    }
}
