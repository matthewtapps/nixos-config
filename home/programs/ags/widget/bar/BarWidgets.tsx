import { bind, GLib, Variable } from "astal"
import { App, Astal } from "astal/gtk3"
import Hyprland from "gi://AstalHyprland"
import Wp from "gi://AstalWp"
import Battery from "gi://AstalBattery"
import { getMicrophoneIcon, getVolumeIcon, toggleMuteEndpoint } from "../utils/audio"
import { getNetworkIconBinding } from "../utils/network"
import { getBatteryIcon } from "../utils/battery"
import { execAsync } from "astal/process"
import { SystemMenuWindowName } from "../systemMenu/SystemMenuWindow";
import Bluetooth from "gi://AstalBluetooth"
import { activeVpnConnections } from "../networkMenu/NetworkControls"
import { isRecording } from "../screenshot/Screenshot";
import { NetworkMenuWindowName } from "../networkMenu/NetworkMenuWindow"
import { BluetoothMenuWindowName } from "../bluetoothMenu/BluetoothMenuWindow"
import Mpris from "gi://AstalMpris"
import { MediaPlayerMenuWindowName } from "../mediaPlayerMenu/MediaPlayerMenuWindow"

export function Workspaces({ vertical, monitorId }: { vertical: boolean, monitorId: number }) {
  const hypr = Hyprland.get_default()

  return <box
    vertical={vertical}>
    {bind(hypr, "workspaces").as((workspaces) => {
      workspaces.sort((a, b) => a.id - b.id);
      return workspaces.map((workspace) => {
        const workspaceVars = Variable.derive([
          bind(workspace.monitor, "id"),
          bind(workspace.monitor, "activeWorkspace")
        ])
        return <box
          visible={
            workspaceVars(([id, _]) => id === monitorId)
          }
          vertical={vertical}>
          <button
            label={workspace.id.toString()}
            className={
              workspaceVars(([_, activeWorkspace]) => (
                activeWorkspace.id === workspace.id
                  ? "activeWorkspace"
                  : "iconButton"
              ))
            }
            onClicked={() => {
              hypr.dispatch("workspace", `${workspace.id}`)
            }}>
          </button>
        </box>
      })
    })}
  </box >
}

export function ClockButton({ css, monitorId }: { css: string, singleLine: boolean, monitorId: number }) {
  const format = "%H:%M:%S - %A %e."

  const time = Variable<string>("").poll(1000, () =>
    GLib.DateTime.new_now_local().format(format)!)

  const calendarWindowName = `calendarwindow${monitorId}`

  return <button
    className="iconButton"
    css={css}
    label={time()}
    onClicked={() => {
      App.toggle_window(calendarWindowName)
    }}>

  </button>
}

export function MediaButton({ css }: { css: string }) {
  const mpris = Mpris.get_default();
  return <box>
    {bind(mpris, "players").as(p => {
      if (!p.length) return <label />;

      const defaultPlayer = p[0];
      if (!defaultPlayer) return <label />;

      const title = bind(defaultPlayer, "title").as(t => t || "Unknown Track")
      const artist = bind(defaultPlayer, "artist").as(a => a || "Unknown Artist")

      const realPosition = Variable(defaultPlayer.position)
      bind(defaultPlayer, "position").subscribe((position) => {
        if (defaultPlayer.playbackStatus === Mpris.PlaybackStatus.PLAYING) {
          realPosition.set(position)
        }
      })
      const playIcon = bind(defaultPlayer, "playbackStatus").as(s =>
        s === Mpris.PlaybackStatus.PLAYING
          ? ""
          : ""
      )

      return <button
        className="iconButton"
        css={css}
        onClick={(_, e) => {
          if (e.button === Astal.MouseButton.PRIMARY) {
            App.toggle_window(MediaPlayerMenuWindowName);
          }
          if (e.button === Astal.MouseButton.SECONDARY) {
            defaultPlayer.play_pause();
          }
        }}
      >
        <box >
          <label label={playIcon} css="margin: 0px 5px 0px 10px" />
          <label label={title} css="margin: 0px 10px 0px 5px" />
          <label>-</label>
          <box css="margin: 0px 5px 0px 10px" />
          <label label={artist} />
        </box>
      </button>
    })}
  </box>
}

export function VpnButton({ css }: { css: string }) {
  return <label
    className="iconButton"
    css={css}
    label="󰯄"
    visible={activeVpnConnections().as((connections) => {
      return connections.length !== 0
    })} />
}

export function ScreenRecordingButton({ css }: { css: string }) {
  return <button
    className="warningIconButton"
    css={css}
    label=""
    visible={isRecording()}
    onClicked={() => {
      execAsync("pkill wf-recorder")
    }} />
}

export function VolumeButton({ css }: { css: string }) {
  const defaultSpeaker = Wp.get_default()!.audio.default_speaker

  const speakerVar = Variable.derive([
    bind(defaultSpeaker, "description"),
    bind(defaultSpeaker, "volume"),
    bind(defaultSpeaker, "mute")
  ])

  return <button
    className="iconButton"
    css={css}
    label={speakerVar(() => getVolumeIcon(defaultSpeaker))}
    onClicked={() => execAsync("pactl set-sink-mute @DEFAULT_SINK@ toggle")}
  />
}

export function MicrophoneButton({ css }: { css: string }) {
  const { defaultMicrophone } = Wp.get_default()!.audio

  const micVar = Variable.derive([
    bind(defaultMicrophone, "description"),
    bind(defaultMicrophone, "volume"),
    bind(defaultMicrophone, "mute")
  ])

  const audio = Wp.get_default()!

  return <button
    css={css}
    className="iconButton"
    label={micVar(() => getMicrophoneIcon(defaultMicrophone))}
    onClicked={() => {
      toggleMuteEndpoint(audio.default_microphone)
    }}
  />
}

export function BluetoothButton({ css }: { css: string }) {
  const bluetooth = Bluetooth.get_default()
  return <button
    css={css}
    className="iconButton"
    label="󰂯"
    visible={bind(bluetooth, "isPowered").as((isPowered) => {
      return isPowered
    })}
    onClicked={() => {
      App.toggle_window(BluetoothMenuWindowName)
    }}
  />
}

export function NetworkButton({ css }: { css: string }) {
  return <button
    css={css}
    className="iconButton"
    label={getNetworkIconBinding()}
    onClicked={() => {
      App.toggle_window(NetworkMenuWindowName)
    }} />
}

export function BatteryButton({ css }: { css: string }) {
  const battery = Battery.get_default()

  let batteryWarningInterval: GLib.Source | null = null

  function warningSound() {
    execAsync('bash -c "play $HOME/.config/hypr/assets/sounds/battery-low.ogg"')
  }

  const batteryVar = Variable.derive([
    bind(battery, "percentage"),
    bind(battery, "state")
  ])

  return <label
    css={css}
    className={batteryVar((value) => {
      if (value[0] > 0.04 || battery.state === Battery.State.CHARGING) {
        if (batteryWarningInterval != null) {
          batteryWarningInterval.destroy()
          batteryWarningInterval = null
        }
        return "iconButton"
      } else {
        if (batteryWarningInterval === null && battery.isBattery) {
          batteryWarningInterval = setInterval(() => {
            warningSound()
          }, 120_000)
          warningSound()
        }
        return "warningIconButton"
      }
    })}
    label={`${batteryVar(() => getBatteryIcon(battery))} ${batteryVar(() => battery.percentage)}%`}
    visible={bind(battery, "isBattery")} />
}

export function MenuButton({ css }: { css: string }) {
  return <button
    css={css}
    className="iconButton"
    label="󱄅"
    onClicked={() => {
      App.toggle_window(SystemMenuWindowName)
    }} />
}
