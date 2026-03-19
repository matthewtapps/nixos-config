import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

// Toast notification popups — one instance per screen.
// Appears at top-left (matching former swaync position), auto-dismisses.
PanelWindow {
    id: root

    required property var screen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notification-popup"

    anchors { top: true; left: true }
    margins.top: 45   // just below the bar
    margins.left: 40

    implicitWidth: 500
    // Height driven by content; zero when nothing to show
    implicitHeight: Math.max(1, popupColumn.implicitHeight)

    color: "transparent"

    // Hide popups while notification center is open
    visible: !Globals.notifCenterVisible && Globals.notifServer.trackedNotifications.count > 0

    Column {
        id: popupColumn
        width: 500
        spacing: 8

        Repeater {
            // Show newest-first, capped at 5
            model: Globals.notifServer.trackedNotifications

            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property var notif: modelData

                visible: index < 5
                width: 500
                height: visible ? notifCol.implicitHeight + 20 : 0

                color: "#333C43"
                border.color: "#555F66"
                border.width: 1
                radius: 4

                // Auto-dismiss
                Timer {
                    interval: notif.expireTimeout > 0 ? notif.expireTimeout : 5000
                    running: parent.visible
                    onTriggered: notif.expire()
                }

                Column {
                    id: notifCol
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 10
                        rightMargin: 30  // room for close button
                    }
                    spacing: 4

                    // App name + summary
                    Text {
                        width: parent.width
                        text: (notif.appName ? "[" + notif.appName + "]  " : "") + (notif.summary || "")
                        color: "#D3C6AA"
                        font.family: "GeistMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    // Body
                    Text {
                        visible: (notif.body || "") !== ""
                        width: parent.width
                        text: notif.body || ""
                        color: "#D3C6AA"
                        font.family: "GeistMono Nerd Font"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }

                // Dismiss button
                Rectangle {
                    anchors { right: parent.right; top: parent.top; margins: 6 }
                    width: 18; height: 18
                    color: closeArea.containsMouse ? "#555F66" : "transparent"
                    radius: 9

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#D3C6AA"
                        font.pixelSize: 9
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: notif.dismiss()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    // Click notification body to dismiss
                    onClicked: notif.dismiss()
                    // Don't steal from close button
                    z: -1
                }
            }
        }
    }
}
