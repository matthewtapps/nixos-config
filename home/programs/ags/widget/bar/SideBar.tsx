import { App, Astal, Gtk } from "astal/gtk3"
import {
  BatteryButton,
  BluetoothButton,
  ClockButton,
  MediaButton,
  MenuButton,
  MicrophoneButton,
  NetworkButton,
  ScreenRecordingButton,
  VolumeButton, VpnButton,
  Workspaces
} from "./BarWidgets";

export default function(monitorId: number) {
  let iconCss = ""

  return <window
    css={`background: transparent;`}
    monitor={monitorId}
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    margin={5}
    anchor={Astal.WindowAnchor.TOP
      | Astal.WindowAnchor.LEFT
      | Astal.WindowAnchor.BOTTOM}
    application={App}>
    <centerbox
      vertical={true}
      className="window"
      css={`
                padding: 2px;
                min-width: 40px;
            `}>
      <box vertical={true}>
        <MenuButton css={"padding-top: 6px;"} />
        <Workspaces vertical={true} monitorId={monitorId} />
      </box>
      <box vertical={true}>
        <MediaButton css={iconCss} />
      </box>
      <box
        vertical={true}
        valign={Gtk.Align.END}>
        <ScreenRecordingButton css={iconCss} />
        <VolumeButton css={iconCss} />
        <MicrophoneButton css={iconCss} />
        <BluetoothButton css={iconCss} />
        <VpnButton css={iconCss} />
        <NetworkButton css={iconCss} />
        <BatteryButton css={iconCss} />
        <ClockButton css={"padding-bottom: 6px;"} singleLine={false} />
      </box>
    </centerbox>
  </window>
}
