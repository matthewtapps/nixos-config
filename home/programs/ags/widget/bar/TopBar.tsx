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

  return <>
    <window
      css={`background: transparent;`}
      monitor={monitorId}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      name="topbar"
      anchor={Astal.WindowAnchor.TOP
        | Astal.WindowAnchor.LEFT
        | Astal.WindowAnchor.RIGHT}
      application={App}>
      <centerbox
        className="window"
        css={`
                min-height: 20px;
            `}>
        <box halign={Gtk.Align.START}>
          <MenuButton css={""} />
          <Workspaces vertical={false} monitorId={monitorId} />
        </box>
        <box halign={Gtk.Align.CENTER}>
          <MediaButton css={""} />
          <ClockButton css={""} singleLine={true} monitorId={monitorId} />
        </box>
        <box halign={Gtk.Align.END}>
          <ScreenRecordingButton css={iconCss} />
          <VolumeButton css={iconCss} />
          <MicrophoneButton css={iconCss} />
          <BluetoothButton css={iconCss} />
          <VpnButton css={iconCss} />
          <NetworkButton css={iconCss} />
          <BatteryButton css={iconCss} />
        </box>
      </centerbox>
    </window>
  </>
}
