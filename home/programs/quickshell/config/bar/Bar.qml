import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

PanelWindow {
    id: root

    required property var screen

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "bar"

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 35
    color: "#333C43"

    // ── Left ──────────────────────────────────────────────────────────────
    Row {
        height: parent.height
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 8
        }
        spacing: 5

        NotificationBell {}
        Workspaces { screen: root.screen }
        SystemStats {}
    }

    // ── Center ────────────────────────────────────────────────────────────
    Clock {
        anchors.centerIn: parent
    }

    // ── Right ─────────────────────────────────────────────────────────────
    Row {
        height: parent.height
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 8
        }
        spacing: 5

        Battery {}
        Backlight {}
        Audio {}
        Network {}
        Bluetooth {}
    }

    // Close notification center when clicking anywhere on the bar
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onClicked: Globals.closeNotifCenter()
        z: -1
    }
}
