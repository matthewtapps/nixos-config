import QtQuick
import ".."

Item {
    height: parent.height
    width: bellText.implicitWidth + 8

    readonly property int unreadCount: Globals.notifServer.trackedNotifications?.count ?? 0
    readonly property bool hasUnread: unreadCount > 0

    Text {
        id: bellText
        anchors.centerIn: parent
        // Bell icon: active vs quiet (nerd font icons)
        text: hasUnread ? "  " : "  "
        color: "#D3C6AA"
        font.family: "GeistMono Nerd Font"
        font.pixelSize: 13
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                Globals.toggleNotifCenter()
            }
        }
        hoverEnabled: true
        onEntered: bellText.opacity = 0.7
        onExited: bellText.opacity = 1.0
    }
}
