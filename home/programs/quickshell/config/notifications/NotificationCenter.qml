import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

// Slide-in notification center panel, replacing swaync.
// Appears at top-left on the primary monitor.
// Toggle via the bell icon in the bar or Alt+N (via IPC — see hyprland config).
PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notification-center"
    WlrLayershell.keyboardFocus: Globals.notifCenterVisible
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    anchors { top: true; left: true; bottom: true }
    margins.top: 35   // below bar
    margins.left: 0

    implicitWidth: 500
    color: "transparent"

    visible: Globals.notifCenterVisible

    // ── Background overlay to close on outside click ──────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: Globals.closeNotifCenter()
        z: -1
    }

    // ── Panel ─────────────────────────────────────────────────────────────
    Rectangle {
        width: 500
        height: parent.height
        color: "#333C43"
        border.color: "#555F66"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // ── Header (title + power buttons) ────────────────────────────
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Control Center"
                    color: "#D3C6AA"
                    font.family: "GeistMono Nerd Font"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }

                Row {
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "  Lock",     cmd: ["hyprlock"] },
                            { label: "  Reboot",   cmd: ["systemctl", "reboot"] },
                            { label: "  Shutdown", cmd: ["systemctl", "poweroff"] },
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            width: lbl.implicitWidth + 16
                            height: 26
                            radius: 4
                            color: ma.containsMouse ? "#3A464C" : "#293136"

                            Text {
                                id: lbl
                                anchors.centerIn: parent
                                text: modelData.label
                                color: "#D3C6AA"
                                font.family: "GeistMono Nerd Font"
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    Globals.closeNotifCenter()
                                    Quickshell.execDetached(modelData.cmd)
                                }
                            }
                        }
                    }
                }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#555F66"
            }

            // ── Notifications title + clear button ────────────────────────
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Notifications (" + Globals.notifServer.trackedNotifications.count + ")"
                    color: "#D3C6AA"
                    font.family: "GeistMono Nerd Font"
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: Globals.notifServer.trackedNotifications.count > 0
                    width: clearLbl.implicitWidth + 16
                    height: 24
                    radius: 4
                    color: clearMa.containsMouse ? "#3A464C" : "#293136"

                    Text {
                        id: clearLbl
                        anchors.centerIn: parent
                        text: "Clear All"
                        color: "#D3C6AA"
                        font.family: "GeistMono Nerd Font"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: clearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            const model = Globals.notifServer.trackedNotifications
                            // Dismiss in reverse order to avoid index shifting
                            for (let i = model.count - 1; i >= 0; i--) {
                                model.get(i).dismiss()
                            }
                        }
                    }
                }
            }

            // ── Notification list ─────────────────────────────────────────
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: Globals.notifServer.trackedNotifications
                spacing: 4
                clip: true

                // "No notifications" placeholder
                Item {
                    anchors.fill: parent
                    visible: Globals.notifServer.trackedNotifications.count === 0

                    Text {
                        anchors.centerIn: parent
                        text: "No notifications"
                        color: "#555F66"
                        font.family: "GeistMono Nerd Font"
                        font.pixelSize: 13
                    }
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property var notif: modelData

                    width: ListView.view.width
                    height: notifBody.implicitHeight + 20
                    color: "#293136"
                    border.color: "#555F66"
                    border.width: 1
                    radius: 4

                    Column {
                        id: notifBody
                        anchors {
                            left: parent.left; right: parent.right; top: parent.top
                            margins: 10; rightMargin: 34
                        }
                        spacing: 3

                        RowLayout {
                            width: parent.width

                            Text {
                                text: notif.summary || "Notification"
                                color: "#D3C6AA"
                                font.family: "GeistMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: notif.appName || ""
                                color: "#A7C080"
                                font.family: "GeistMono Nerd Font"
                                font.pixelSize: 11
                            }
                        }

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

                    // Close button
                    Rectangle {
                        anchors { right: parent.right; top: parent.top; margins: 6 }
                        width: 20; height: 20
                        radius: 10
                        color: closeMa.containsMouse ? "#555F66" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: "#D3C6AA"
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: notif.dismiss()
                        }
                    }
                }
            }
        }
    }
}
