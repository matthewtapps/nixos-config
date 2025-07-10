import { Astal, Gtk, Gdk } from "astal/gtk3";
import Notifd from "gi://AstalNotifd";
import Notification from "./Notification";
import { type Subscribable } from "astal/binding";
import { Variable, bind, GLib } from "astal";

// see comment below in constructor
const TIMEOUT_DELAY = 7_000;
const NOTIFICATION_EXPIRY_TIME = 4 * 60 * 60 * 1000; // 4 hours in milliseconds

// The purpose if this class is to replace Variable<Array<Widget>>
// with a Map<number, Widget> type in order to track notification widgets
// by their id, while making it conviniently bindable as an array
class NotifiationMap implements Subscribable {
  // the underlying map to keep track of id widget pairs
  private map: Map<number, Gtk.Widget> = new Map();

  // Track notification timestamps for expiry
  private timestamps: Map<number, number> = new Map();

  // it makes sense to use a Variable under the hood and use its
  // reactivity implementation instead of keeping track of subscribers ourselves
  private var: Variable<Array<Gtk.Widget>> = Variable([]);

  // notify subscribers to rerender when state changes
  private notifiy() {
    this.var.set([...this.map.values()].reverse());
  }

  // Clean up expired notifications
  private cleanupExpiredNotifications() {
    const now = Date.now();
    const expiredIds: number[] = [];

    this.timestamps.forEach((timestamp, id) => {
      if (now - timestamp > NOTIFICATION_EXPIRY_TIME) {
        expiredIds.push(id);
      }
    });

    expiredIds.forEach((id) => {
      this.delete(id);
    });

    // Schedule next cleanup
    setTimeout(() => this.cleanupExpiredNotifications(), 60000); // Check every minute
  }

  constructor() {
    const notifd = Notifd.get_default();

    /**
     * uncomment this if you want to
     * ignore timeout by senders and enforce our own timeout
     * note that if the notification has any actions
     * they might not work, since the sender already treats them as resolved
     */
    // notifd.ignoreTimeout = true

    notifd.connect("notified", (_, id) => {
      let hideTimeout: GLib.Source | null = null;

      if (notifd.dontDisturb) {
        return;
      }

      const notification = notifd.get_notification(id);

      if (!notification) {
        return;
      }

      if (notification.app_name === "spotify_player") {
        notification.dismiss();
        return;
      }

      // Record timestamp for this notification
      this.timestamps.set(id, Date.now());

      this.set(
        id,
        Notification({
          notification: notifd.get_notification(id)!,

          // once hovering over the notification is done
          // destroy the widget without calling notification.dismiss()
          // so that it acts as a "popup" and we can still display it
          // in a notification center like widget
          // but clicking on the close button will close it
          onHoverLost: () => {
            hideTimeout = setTimeout(() => {
              this.delete(id);
              hideTimeout?.destroy();
              hideTimeout = null;
            }, TIMEOUT_DELAY);
          },
          onHover() {
            hideTimeout?.destroy();
            hideTimeout = null;
          },

          // notifd by default does not close notifications
          // until user input or the timeout specified by sender
          // which we set to ignore above
          setup: () => {
            hideTimeout = setTimeout(() => {
              this.delete(id);
              hideTimeout?.destroy();
              hideTimeout = null;
            }, TIMEOUT_DELAY);
          },
          useHistoryCss: false,
        }),
      );
    });

    // notifications can be closed by the outside before
    // any user input, which have to be handled too
    notifd.connect("resolved", (_, id) => {
      this.delete(id);
    });

    // Start the cleanup process
    setTimeout(() => this.cleanupExpiredNotifications(), 60000);
  }

  private set(key: number, value: Gtk.Widget) {
    // in case of replacecment destroy previous widget
    this.map.get(key)?.destroy();
    this.map.set(key, value);
    this.notifiy();
  }

  private delete(key: number) {
    this.map.get(key)?.destroy();
    this.map.delete(key);
    this.timestamps.delete(key);
    this.notifiy();
  }

  // needed by the Subscribable interface
  get() {
    return this.var.get();
  }

  // needed by the Subscribable interface
  subscribe(callback: (list: Array<Gtk.Widget>) => void) {
    return this.var.subscribe(callback);
  }
}

export default function NotificationPopups(gdkmonitor: Gdk.Monitor) {
  const { BOTTOM, RIGHT } = Astal.WindowAnchor;
  const notifs = new NotifiationMap();

  return (
    <window
      child={<box vertical={true}>{bind(notifs)}</box>}
      className="NotificationPopups"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={BOTTOM | RIGHT}
    ></window>
  );
}
