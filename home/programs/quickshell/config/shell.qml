//@ pragma ShellId quickshell-bar
import Quickshell
import Quickshell.Io
import "bar"
import "notifications"

ShellRoot {
    // IPC handler so `quickshell ipc call bar toggleNotifCenter` works
    // Used by the hyprland Alt+N keybinding
    IpcHandler {
        target: "bar"
        function toggleNotifCenter(): void {
            Globals.toggleNotifCenter()
        }
    }

    // One bar per screen
    Variants {
        model: Quickshell.screens
        delegate: Bar {
            required property var modelData
            screen: modelData
        }
    }

    // Notification popups per screen
    Variants {
        model: Quickshell.screens
        delegate: NotificationPopups {
            required property var modelData
            screen: modelData
        }
    }

    // Single notification center panel (appears on primary monitor)
    NotificationCenter {}
}
