import { App, Astal } from "astal/gtk3"
import EndpointControls from "./EndpointControls";
import Wp from "gi://AstalWp"
import { bind } from "astal"
import { Gtk, Gdk } from "astal/gtk3"
import { getMicrophoneIcon, getVolumeIcon } from "../utils/audio";
import PowerOptions from "./PowerOptions";
import NotificationHistory from "./NotificationHistory";
import Divider from "../common/Divider";
import MediaPlayers from "../mediaPlayerMenu/MediaPlayers";

export const SystemMenuWindowName = "systemMenuWindow"

export default function() {
  const { audio } = Wp.get_default()!

  let window: Gtk.Window

  return <window
    exclusivity={Astal.Exclusivity.NORMAL}
    anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.BOTTOM}
    layer={Astal.Layer.TOP}
    css={`background: transparent;`}
    name={SystemMenuWindowName}
    application={App}
    margin={5}
    keymode={Astal.Keymode.ON_DEMAND}
    visible={false}
    onKeyPressEvent={function(self, event: Gdk.Event) {
      if (event.get_keyval()[1] === Gdk.KEY_Escape) {
        self.hide()
      }
    }}
    setup={(self) => {
      window = self
    }}>
    <box
      vertical={true}>
      <box
        vertical={true}
        setup={(self) => {
          setTimeout(() => {
            bind(window, "hasToplevelFocus").subscribe((hasFocus) => {
              if (hasFocus) {
                self.className = "focusedWindow"
              } else {
                self.className = "window"
              }
            })
          }, 1_000)
        }}>
        <scrollable
          className="scrollWindow"
          vscroll={Gtk.PolicyType.AUTOMATIC}
          propagateNaturalHeight={true}
          widthRequest={400}>
          <box
            css={`margin: 0 10px 0 10px;`}
            vertical={true}>
            <box css={"margin-top: 20px;"} />
            <EndpointControls
              defaultEndpoint={audio.default_speaker}
              endpointsBinding={bind(audio, "speakers")}
              getIcon={getVolumeIcon} />
            <EndpointControls
              defaultEndpoint={audio.default_microphone}
              endpointsBinding={bind(audio, "microphones")}
              getIcon={getMicrophoneIcon} />
            {/*Disabling Media players since it seems to cause heavy lag when I use spotify-player (tui spotify)*/}
            {/*Also requires gvfs package installed*/}
            <box css={"margin-top: 20px;"} />
            <Divider css={"margin: 0 60px 0 60px;"} />
            <box css={"margin-top: 20px;"} />
            <PowerOptions />
            <box css={"margin-top: 20px;"} />
            <NotificationHistory />
          </box>
        </scrollable>
      </box>
      <box
        vexpand={true} />
    </box>
  </window>
}
