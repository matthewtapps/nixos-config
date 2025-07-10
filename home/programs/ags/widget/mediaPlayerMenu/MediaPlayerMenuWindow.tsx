import { App, Astal } from "astal/gtk3";
import { bind, Variable } from "astal";
import { Gtk, Gdk } from "astal/gtk3";
import Mpris from "gi://AstalMpris";
import Wp from "gi://AstalWp";
import { getVolumeIcon } from "../utils/audio";

export const MediaPlayerMenuWindowName = "mediaPlayerMenuWindow";

function lengthStr(length: number) {
  const min = Math.floor(length / 60);
  const sec = Math.floor(length % 60);
  const sec0 = sec < 10 ? "0" : "";
  return `${min}:${sec0}${sec}`;
}

function MediaPlayerWidget() {
  const mpris = Mpris.get_default();
  const audio = Wp.get_default()?.audio;

  return (
    <box
      vertical={true}
      child={bind(mpris, "players").as((players) => {
        if (!players.length) {
          return (
            <box
              vertical={true}
              css="padding: 40px;"
              halign={Gtk.Align.CENTER}
              valign={Gtk.Align.CENTER}
            >
              <label
                className="labelLarge"
                label="󰝚"
                css="font-size: 48px; margin-bottom: 16px; opacity: 0.5;"
              />
              <label
                className="labelMedium"
                label="No media playing"
                css="opacity: 0.7;"
              />
            </box>
          );
        }

        const player = players[0];
        if (!player) return <box />;

        // Track real position for smooth updates
        const realPosition = Variable(player.position);
        bind(player, "position").subscribe((position) => {
          if (player.playbackStatus === Mpris.PlaybackStatus.PLAYING) {
            realPosition.set(position);
          }
        });

        const playIcon = bind(player, "playbackStatus").as((s) =>
          s === Mpris.PlaybackStatus.PLAYING ? "⏸" : "▶",
        );

        const title = bind(player, "title").as((t) => t || "Unknown Track");
        const artist = bind(player, "artist").as((a) => a || "Unknown Artist");
        const artUrl = bind(player, "artUrl").as((url) => url || "");

        return (
          <box vertical={true} css="padding: 20px;" widthRequest={350}>
            {/* Album Art */}
            <box
              halign={Gtk.Align.CENTER}
              css="margin-bottom: 20px;"
              child={artUrl.as((url) => {
                if (url) {
                  return (
                    <box
                      css={`
                        min-width: 200px;
                        min-height: 200px;
                        border-radius: 12px;
                        background-image: url("${url}");
                        background-size: cover;
                        background-position: center;
                        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
                      `}
                    />
                  );
                } else {
                  return (
                    <box
                      halign={Gtk.Align.CENTER}
                      valign={Gtk.Align.CENTER}
                      css={`
                        min-width: 200px;
                        min-height: 200px;
                        border-radius: 12px;
                        background: linear-gradient(135deg, #2d3748, #4a5568);
                        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
                      `}
                      child={
                        <label
                          className="labelLarge"
                          label="♪"
                          css="font-size: 64px; opacity: 0.5;"
                        />
                      }
                    ></box>
                  );
                }
              })}
            ></box>

            {/* Track Info */}
            <box vertical={true} css="margin-bottom: 20px;">
              <label
                className="labelLargeBold"
                label={title}
                halign={Gtk.Align.CENTER}
                css="margin-bottom: 4px;"
                truncate={true}
              />
              <label
                className="labelMedium"
                label={artist}
                halign={Gtk.Align.CENTER}
                css="opacity: 0.7;"
                truncate={true}
              />
            </box>

            {/* Progress Bar */}
            <box vertical={true} css="margin-bottom: 20px;">
              <box vertical={false} css="margin-bottom: 8px;">
                <label
                  className="labelSmall"
                  halign={Gtk.Align.START}
                  visible={bind(player, "length").as((l) => l > 0)}
                  label={realPosition().as(lengthStr)}
                />
                <box hexpand={true} />
                <label
                  className="labelSmall"
                  halign={Gtk.Align.END}
                  visible={bind(player, "length").as((l) => l > 0)}
                  label={bind(player, "length").as((l) =>
                    l > 0 ? lengthStr(l) : "0:00",
                  )}
                />
              </box>
              <slider
                className="mediaProgressSlider"
                hexpand={true}
                visible={bind(player, "length").as((l) => l > 0)}
                onDragged={({ value }) => {
                  player.position = value * player.length;
                  realPosition.set(player.position);
                }}
                value={realPosition().as((position) => {
                  return player.length > 0 ? position / player.length : 0;
                })}
                css={`
                  min-height: 6px;
                  margin: 4px 0;
                `}
              />
            </box>

            {/* Media Controls */}
            <box
              halign={Gtk.Align.CENTER}
              css="margin-bottom: 20px;"
              spacing={12}
            >
              {/* Shuffle */}
              <button
                className="mediaControlButton"
                visible={bind(player, "shuffleStatus").as(
                  (shuffle) => shuffle !== Mpris.Shuffle.UNSUPPORTED,
                )}
                label={bind(player, "shuffleStatus").as((shuffle) => {
                  return shuffle === Mpris.Shuffle.ON ? "🔀" : "🔀";
                })}
                css={bind(player, "shuffleStatus").as((shuffle) => {
                  return shuffle === Mpris.Shuffle.ON
                    ? "color: #A7C080; font-size: 20px;"
                    : "opacity: 0.5; font-size: 20px;";
                })}
                onClicked={() => {
                  if (player.shuffleStatus === Mpris.Shuffle.ON) {
                    player.set_shuffle_status(Mpris.Shuffle.OFF);
                  } else {
                    player.set_shuffle_status(Mpris.Shuffle.ON);
                  }
                }}
              />

              {/* Previous */}
              <button
                className="mediaControlButton"
                visible={bind(player, "canGoPrevious")}
                label="⏮"
                css="font-size: 24px;"
                onClicked={() => player.previous()}
              />

              {/* Play/Pause */}
              <button
                className="mediaControlButtonPrimary"
                visible={bind(player, "canControl")}
                label={playIcon}
                css="font-size: 32px; padding: 12px 16px;"
                onClicked={() => player.play_pause()}
              />

              {/* Next */}
              <button
                className="mediaControlButton"
                visible={bind(player, "canGoNext")}
                label="⏭"
                css="font-size: 24px;"
                onClicked={() => player.next()}
              />

              {/* Repeat */}
              <button
                className="mediaControlButton"
                visible={bind(player, "loopStatus").as(
                  (status) => status !== Mpris.Loop.UNSUPPORTED,
                )}
                label={bind(player, "loopStatus").as((status) => {
                  if (status === Mpris.Loop.TRACK) return "🔂";
                  if (status === Mpris.Loop.PLAYLIST) return "🔁";
                  return "🔁";
                })}
                css={bind(player, "loopStatus").as((status) => {
                  return status !== Mpris.Loop.NONE
                    ? "color: #A7C080; font-size: 20px;"
                    : "opacity: 0.5; font-size: 20px;";
                })}
                onClicked={() => {
                  if (player.loopStatus === Mpris.Loop.NONE) {
                    player.set_loop_status(Mpris.Loop.PLAYLIST);
                  } else if (player.loopStatus === Mpris.Loop.PLAYLIST) {
                    player.set_loop_status(Mpris.Loop.TRACK);
                  } else {
                    player.set_loop_status(Mpris.Loop.NONE);
                  }
                }}
              />
            </box>

            {/* Volume Control */}
            {audio && (
              <box vertical={false} css="margin-top: 8px;" spacing={12}>
                <button
                  className="iconButton"
                  label={bind(audio.default_speaker, "mute").as(() =>
                    getVolumeIcon(audio.default_speaker),
                  )}
                  onClicked={() => {
                    audio.default_speaker.set_mute(!audio.default_speaker.mute);
                  }}
                />
                <slider
                  className="volumeSlider"
                  hexpand={true}
                  onDragged={({ value }) =>
                    (audio.default_speaker.volume = value)
                  }
                  value={bind(audio.default_speaker, "volume")}
                  css="min-height: 6px;"
                />
                <label
                  className="labelSmall"
                  label={bind(audio.default_speaker, "volume").as(
                    (v) => `${Math.round(v * 100)}%`,
                  )}
                  css="min-width: 36px;"
                />
              </box>
            )}
          </box>
        );
      })}
    />
  );
}

export default function () {
  let window: Gtk.Window;
  let dismissTimeout: any = null;

  const scheduleAutoDismiss = () => {
    if (dismissTimeout) {
      clearTimeout(dismissTimeout);
    }
    dismissTimeout = setTimeout(() => {
      if (window.visible && !window.hasToplevelFocus) {
        App.toggle_window(MediaPlayerMenuWindowName);
      }
    }, 3000); // 3 second delay for media player
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
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM}
      layer={Astal.Layer.TOP}
      css={`
        background: transparent;
      `}
      name={MediaPlayerMenuWindowName}
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

        // Auto-dismiss on focus loss
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
            child={<MediaPlayerWidget />}
          />
          <box vexpand={true} />
        </box>
      }
    />
  );
}
