import Notifd from "gi://AstalNotifd"
import { bind, Variable, GLib } from "astal"
import Notification from "../notification/Notification"
import { Gtk } from "astal/gtk3"

const NOTIFICATION_EXPIRY_TIME = 4 * 60 * 60 * 1000 // 4 hours in milliseconds

export default function() {
  const notifications = Notifd.get_default()
  
  // Track when notifications were created
  const notificationTimestamps = Variable<Map<string, number>>(new Map())
  
  // Function to clean up expired notifications
  const cleanupExpiredNotifications = () => {
    const now = Date.now()
    const timestamps = notificationTimestamps.get()
    const currentNotifications = notifications.notifications
    
    currentNotifications.forEach((notification) => {
      const notifTime = timestamps.get(notification.id.toString()) || notification.time * 1000
      
      if (now - notifTime > NOTIFICATION_EXPIRY_TIME) {
        notification.dismiss()
        timestamps.delete(notification.id.toString())
      }
    })
    
    notificationTimestamps.set(new Map(timestamps))
    
    // Schedule next cleanup
    setTimeout(cleanupExpiredNotifications, 60000) // Check every minute
  }
  
  // Start cleanup process
  setTimeout(cleanupExpiredNotifications, 60000)
  
  // Track new notifications
  notifications.connect("notified", (_, id) => {
    const timestamps = notificationTimestamps.get()
    timestamps.set(id.toString(), Date.now())
    notificationTimestamps.set(new Map(timestamps))
  })

  return <box
    vertical={true}
    css={`margin-bottom: 2px;`}>
    <box
      css={`margin: 0 20px 0 20px;`}
      vertical={false}>
      <button
        className="iconButton"
        label={bind(notifications, "dontDisturb").as((dnd) => {
          return dnd ? "󰂛" : "󰂚"
        })}
        onClicked={() => {
          notifications.set_dont_disturb(!notifications.dontDisturb)
        }} />
      <label
        className="labelMediumBold"
        label="Notifications" />
      <box hexpand={true} />
      <button
        className="iconButton"
        label="Clear all"
        onClicked={() => {
          const timestamps = notificationTimestamps.get()
          notifications.notifications.forEach((notification) => {
            notification.dismiss()
            timestamps.delete(notification.id.toString())
          })
          notificationTimestamps.set(new Map(timestamps))
        }} />
    </box>
    {bind(notifications, "notifications").as((notificationsList) => {
      // Filter out expired notifications
      const now = Date.now()
      const timestamps = notificationTimestamps.get()
      
      const validNotifications = notificationsList.filter((notification) => {
        const notifTime = timestamps.get(notification.id.toString()) || notification.time * 1000
        return (now - notifTime) <= NOTIFICATION_EXPIRY_TIME
      })
      
      if (validNotifications.length === 0) {
        return <label
          className="labelSmall"
          css={`margin-top: 8px; margin-bottom: 20px;`}
          halign={Gtk.Align.CENTER}
          label="All caught up" />
      } else {
        return validNotifications.map((notification) => {
          return <Notification
            setup={() => { }}
            onHoverLost={() => { }}
            onHover={() => { }}
            notification={notification}
            useHistoryCss={true} />
        })
      }
    })}
  </box>
}
