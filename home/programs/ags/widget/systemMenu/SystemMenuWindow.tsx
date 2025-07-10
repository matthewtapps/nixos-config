import { App, Astal } from "astal/gtk3";
import EndpointControls from "./EndpointControls";
import Wp from "gi://AstalWp";
import { bind } from "astal";
import { Gtk, Gdk } from "astal/gtk3";
import { getMicrophoneIcon, getVolumeIcon } from "../utils/audio";
import PowerOptions from "./PowerOptions";
import NotificationHistory from "./NotificationHistory";
import Divider from "../common/Divider";

export const SystemMenuWindowName = "systemMenuWindow";

export default function () {
  const { audio } = Wp.get_default()!;

  let window: Gtk.Window;
  let dismissTimeout: any = null;

  const scheduleAutoDismiss = () => {
    if (dismissTimeout) {
      clearTimeout(dismissTimeout);
    }
    dismissTimeout = setTimeout(() => {
      if (window.visible && !window.hasToplevelFocus) {
        App.toggle_window(SystemMenuWindowName);
      }
    }, 2000); // 2 second delay
  };

  const cancelAutoDismiss = () => {
    if (dismissTimeout) {
      clearTimeout(dismissTimeout);
      dismissTimeout = null;
    }
  };

  return (
    <window
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={
        Astal.WindowAnchor.TOP |
        Astal.WindowAnchor.LEFT |
        Astal.WindowAnchor.BOTTOM
      }
      layer={Astal.Layer.TOP}
      css={`
        background: transparent;
      `}
      name={SystemMenuWindowName}
      application={App}
      margin={5}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
      onKeyPressEvent={function (self, event: Gdk.Event) {
        if (event.get_keyval()[1] === Gdk.KEY_Escape) {
          self.hide();
        }
      }}
      setup={(self) => {
        window = self;

        // Simple focus-based auto-dismiss
        self.connect("notify::has-toplevel-focus", () => {
          if (!self.hasToplevelFocus && self.visible) {
            scheduleAutoDismiss();
          } else {
            cancelAutoDismiss();
          }
        });

        self.connect("notify::visible", () => {
          if (!self.visible) {
            cancelAutoDismiss();
          }
        });
      }}
      child={
        <box vertical={true}>
          <box
            vertical={true}
            setup={(self) => {
              setTimeout(() => {
                bind(window, "hasToplevelFocus").subscribe((hasFocus) => {
                  if (hasFocus) {
                    self.className = "focusedWindow";
                  } else {
                    self.className = "window";
                  }
                });
              }, 1_000);
            }}
            child={
              <scrollable
                className="scrollWindow"
                vscroll={Gtk.PolicyType.AUTOMATIC}
                propagateNaturalHeight={true}
                widthRequest={400}
                child={
                  <box
                    css={`
                      margin: 0 10px 0 10px;
                    `}
                    vertical={true}
                  >
                    <box css={"margin-top: 20px;"} />
                    <EndpointControls
                      defaultEndpoint={audio.default_speaker}
                      endpointsBinding={bind(audio, "speakers")}
                      getIcon={getVolumeIcon}
                    />
                    <EndpointControls
                      defaultEndpoint={audio.default_microphone}
                      endpointsBinding={bind(audio, "microphones")}
                      getIcon={getMicrophoneIcon}
                    />
                    <box css={"margin-top: 20px;"} />
                    <Divider css={"margin: 0 60px 0 60px;"} />
                    <box css={"margin-top: 20px;"} />
                    <PowerOptions />
                    <box css={"margin-top: 20px;"} />
                    <NotificationHistory />
                  </box>
                }
              />
            }
          />
          <box vexpand={true} />
        </box>
      }
    />
  );
}
