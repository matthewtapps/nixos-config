import { opt, mkOptions } from "lib/option";
import { distro } from "lib/variables";
import { icon } from "lib/utils";
import icons from "lib/icons";

const options = mkOptions(OPTIONS, {
  autotheme: opt(false),

  wallpaper: {
    resolution: opt<import("service/wallpaper").Resolution>(1920),
    market: opt<import("service/wallpaper").Market>("random"),
  },

  theme: {
    dark: {
      primary: {
        bg: opt("#48584E"),
        fg: opt("#A7C080"),
      },
      error: {
        bg: opt("#5C3F4F"),
        fg: opt("#E67E80"),
      },
      bg: opt("#333C43"),
      fg: opt("#D3C6AA"),
      widget: opt("#eeeeee"),
      border: opt("#eeeeee"),
    },
    light: {
      primary: {
        bg: opt("#E5E6C5"),
        fg: opt("#8DA101"),
      },
      error: {
        bg: opt("#F4DBD0"),
        fg: opt("#F65552"),
      },
      bg: opt("#F3EAD3"),
      fg: opt("#5C6A72"),
      widget: opt("#080808"),
      border: opt("#080808"),
    },

    blur: opt(0),
    scheme: opt<"dark" | "light">("dark"),
    widget: { opacity: opt(94) },
    border: {
      width: opt(1),
      opacity: opt(96),
    },

    shadows: opt(true),
    padding: opt(7),
    spacing: opt(12),
    radius: opt(11),
  },

  transition: opt(200),

  font: {
    size: opt(13),
    name: opt("CommitMono Nerd Font"),
  },

  bar: {
    flatButtons: opt(true),
    position: opt<"top" | "bottom">("top"),
    corners: opt(0),
    transparent: opt(false),
    layout: {
      start: opt<Array<import("widget/bar/Bar").BarWidget>>([
        "workspaces",
        "expander",
        "messages",
      ]),
      center: opt<Array<import("widget/bar/Bar").BarWidget>>(["date"]),
      end: opt<Array<import("widget/bar/Bar").BarWidget>>([
        "media",
        "expander",
        "systray",
        "screenrecord",
        "system",
        "battery",
        "powermenu",
      ]),
    },
    launcher: {
      icon: {
        colored: opt(true),
        icon: opt(icon(distro.logo, icons.ui.search)),
      },
      label: {
        colored: opt(false),
        label: opt(" Applications"),
      },
      action: opt(() => App.toggleWindow("launcher")),
    },
    date: {
      format: opt("%H:%M:%S - %A %e."),
      action: opt(() => App.toggleWindow("datemenu")),
    },
    battery: {
      bar: opt<"hidden" | "regular" | "whole">("hidden"),
      charging: opt("#00D787"),
      percentage: opt(true),
      blocks: opt(7),
      width: opt(50),
      low: opt(30),
    },
    workspaces: {
      workspaces: opt(7),
    },
    taskbar: {
      iconSize: opt(0),
      monochrome: opt(false),
      exclusive: opt(true),
    },
    messages: {
      action: opt(() => App.toggleWindow("datemenu")),
    },
    systray: {
      ignore: opt(["KDE Connect Indicator", "spotify-client"]),
    },
    media: {
      monochrome: opt(true),
      preferred: opt("spotify"),
      direction: opt<"left" | "right">("right"),
      format: opt("{artists} - {title}"),
      length: opt(40),
    },
    powermenu: {
      monochrome: opt(false),
      action: opt(() => App.toggleWindow("powermenu")),
    },
  },

  launcher: {
    width: opt(0),
    margin: opt(80),
    nix: {
      pkgs: opt("nixpkgs/nixos-unstable"),
      max: opt(8),
    },
    sh: {
      max: opt(16),
    },
    apps: {
      iconSize: opt(62),
      max: opt(6),
      favorites: opt([
        [
          "firefox",
          "wezterm",
          "org.gnome.Nautilus",
          "org.gnome.Calendar",
          "spotify",
        ],
      ]),
    },
  },

  overview: {
    scale: opt(9),
    workspaces: opt(7),
    monochromeIcon: opt(true),
  },

  powermenu: {
    sleep: opt("systemctl suspend"),
    reboot: opt("systemctl reboot"),
    logout: opt("pkill Hyprland"),
    shutdown: opt("shutdown now"),
    layout: opt<"line" | "box">("line"),
    labels: opt(true),
  },

  quicksettings: {
    avatar: {
      image: opt(`/var/lib/AccountsService/icons/${Utils.USER}`),
      size: opt(70),
    },
    width: opt(380),
    position: opt<"left" | "center" | "right">("right"),
    networkSettings: opt("gtk-launch gnome-control-center"),
    media: {
      monochromeIcon: opt(true),
      coverSize: opt(100),
    },
  },

  datemenu: {
    position: opt<"left" | "center" | "right">("center"),
    weather: {
      interval: opt(60_000),
      unit: opt<"metric" | "imperial" | "standard">("metric"),
      key: opt<string>(
        JSON.parse(Utils.readFile(`${App.configDir}/.weather`) || "{}")?.key ||
        "",
      ),
      cities: opt<Array<number>>(
        JSON.parse(Utils.readFile(`${App.configDir}/.weather`) || "{}")
          ?.cities || [],
      ),
    },
  },

  osd: {
    progress: {
      vertical: opt(true),
      pack: {
        h: opt<"start" | "center" | "end">("end"),
        v: opt<"start" | "center" | "end">("center"),
      },
    },
    microphone: {
      pack: {
        h: opt<"start" | "center" | "end">("center"),
        v: opt<"start" | "center" | "end">("end"),
      },
    },
  },

  notifications: {
    position: opt<Array<"top" | "bottom" | "left" | "right">>(["top", "right"]),
    blacklist: opt(["spotify_player"]),
    width: opt(440),
  },

  hyprland: {
    gaps: opt(2.4),
    inactiveBorder: opt("#282828"),
    gapsWhenOnly: opt(false),
  },
});

globalThis["options"] = options;
export default options;
