pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

// Shared state and notification server for the whole shell.
// Access from any component via: Globals.someProperty
QtObject {
    id: root

    property bool notifCenterVisible: false

    readonly property NotificationServer notifServer: NotificationServer {
        keepOnReload: true
        onNotification: notif => {
            notif.tracked = true
        }
    }

    function toggleNotifCenter() {
        notifCenterVisible = !notifCenterVisible
    }

    function closeNotifCenter() {
        notifCenterVisible = false
    }
}
