{ pkgs, ... }:
{
  # home.file.".config/waybar/scripts/notifications.sh" = {
  #   source = ./scripts/notifications.sh;
  #   executable = true;
  # };

  home.packages = with pkgs; [
    blueman
    networkmanagerapplet
    pavucontrol
    wofi
    jq
    nerd-fonts.geist-mono
  ];

  services.swaync = {
    enable = true;
    settings = {
      positionX = "left";
      positionY = "top";
      control-center-margin-top = 40;
      control-center-margin-bottom = 0;
      control-center-margin-right = 0;
      control-center-margin-left = 40;
      notification-icon-size = 64;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;
      fit-to-screen = false;
      control-center-width = 500;
      control-center-height = 800;
      notification-window-width = 500;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;
      notification-visibility = {
        spotify_player = {
          state = "muted";
          urgency = "Low";
        };
      };

      widgets = [
        "menubar#label"
        "buttons-grid"
        "volume"
        "mpris"
        "title"
        "dnd"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd = {
          text = "Do Not Disturb";
        };
        label = {
          max-lines = 1;
          text = "Control Center";
        };
        mpris = {
          image-size = 96;
          image-radius = 12;
        };
        volume = {
          label = "";
        };
        "menubar#label" = {
          "menu#power-buttons" = {
            label = "";
            position = "left";
            actions = [
              {
                label = "  Reboot";
                command = "systemctl reboot";
              }
              {
                label = "  Lock";
                command = "hyprlock";
              }
              {
                label = "  Shut down";
                command = "systemctl poweroff";
              }
            ];
          };
        };
      };
    };

    style = ''
      @define-color noti-border-color #555F66;
      @define-color noti-bg #333C43;
      @define-color noti-bg-dark #293136;
      @define-color noti-bg-hover-alt #333C43;
      @define-color noti-bg-alt #333C43;
      @define-color noti-fg #D3C6AA;
      @define-color noti-bg-hover #D3C6AA;
      @define-color noti-bg-focus #333C43;
      @define-color noti-close-bg #333C43;
      @define-color noti-close-bg-hover #333C43;
      @define-color noti-urgent #333C43;
      @define-color bg-selected #A7C080;

      *{
        font-family: "Geist";
        color: @noti-fg;
      }

      .notification-background {
        background: transparent;
      }

      .notification-row {
        border: none;
      }

      .notification-row:focus,
      .notification-row:hover {
        border: none;
      }

      .notification {
        background: @noti-bg;
        border: 1px solid @noti-border-color;
        border-radius: 4px;
        box-shadow: none;
        padding: 0;
      }

      .low,
      .normal,
      .critical {
        background: @noti-bg;
      }

      .low .notification-content,
      .normal .notification-content,
      .critical .notification-content {
        background: @noti-bg;
      }

      .notification-content {
        background: @noti-bg;
        border-radius: 4px;
      }

      .close-button {
        background: @noti-close-bg;
        color: @noti-fg;
        text-shadow: none;
        padding: 0;
        border-radius: 100%;
        margin-top: 10px;
        margin-right: 16px;
        box-shadow: none;
        border: none;
        min-width: 24px;
        min-height: 24px;
      }

      .close-button:hover {
        box-shadow: none;
        background: @noti-close-bg-hover;
        transition: all 0.15s ease-in-out;
        border: none;
      }

      .notification-default-action,
      .notification-action {
        box-shadow: none;
        background: @noti-bg;
        border: none;
        color: @noti-fg;
      }

      .notification-default-action:hover,
      .notification-action:hover {
        background: @noti-bg-alt;
      }

      .notification-default-action {
        border-radius: 4px;
      }

      /* When alternative actions are visible */
      .notification-default-action:not(:only-child) {
        border-bottom-left-radius: 0px;
        border-bottom-right-radius: 0px;
      }

      .notification-action {
        background: @noti-bg;
        border-radius: 0px;
        border-top: none;
        border-right: none;
      }

      /* add bottom border radius to eliminate clipping */
      .notification-action:first-child {
        border-bottom-left-radius: 4px;
      }

      .notification-action:last-child {
        border-bottom-right-radius: 4px;
        border-right: 1px solid @noti-border-color;
      }

      .image {}

      .body-image {
        margin-top: 6px;
        border-radius: 0;
      }

      .summary {
        font-size: 14px;
        font-weight: bold;
        background: transparent;
        color: @noti-fg;
        text-shadow: none;
      }

      .time {
        font-size: 13px;
        font-weight: bold;
        background: transparent;
        color: @noti-fg;
        text-shadow: none;
        margin-right: 18px;
      }

      .body {
        font-size: 12px;
        font-weight: normal;
        background: transparent;
        color: @noti-fg;
        text-shadow: none;
      }

      /* The "Notifications" and "Do Not Disturb" text widget */
      .top-action-title {
        text-shadow: none;
      }

      .control-center {
        background: @noti-bg;
        border-radius: 0;
        border: 1px solid @noti-border-color;
      }

      .control-center-list {
        background: @noti-bg;
      }

      .floating-notifications {
        background: transparent;
      }

      .notifications {
        background: @noti-bg;
      }

      .notification-group {
        background: @noti-bg;
      }

      /* Window behind control center and on all other monitors */
      .blank-window {
        background: transparent;
      }

      /*** Widgets ***/

      /* Title widget */
      .widget-title {
        margin: 8px;
        font-size: 16px;
      }

      .widget-title>button {
        font-size: initial;
        color: white;
        text-shadow: none;
        background: @noti-bg;
        border: none;
        box-shadow: none;
        border-radius: 4px;
      }

      .widget-title>button:hover {
        background: @noti-bg-hover;
      }

      /* DND widget */
      .widget-dnd {
        margin: 8px;
        font-size: 1.1rem;
      }

      .widget-dnd>switch {
        font-size: initial;
        border-radius: 12px;
        background: @noti-bg-dark;
        border: none;
        box-shadow: none;
      }

      .widget-dnd>switch:checked {
        background: @bg-selected;
      }

      .widget-dnd>switch slider {
        background: @noti-bg-hover;
        border-radius: 10px;
      }

      /* Label widget */
      .widget-label {
        margin: 4px 8px 8px;
      }

      .widget-label>label {
        font-size: 16px;
      }

      /* Mpris widget */
      .widget-mpris {
        box-shadow: none;
      }

      .widget-mpris-player {
        box-shadow: none;
        border: 1px solid @noti-border-color;
      }

      .widget-mpris-title {
        font-weight: bold;
        font-size: 1.25rem;
      }

      .widget-mpris-subtitle {
        font-size: 1.1rem;
      }

      /* Volume and Brightness Widget*/

      .widget-volume {
        background-color: @noti-bg;
        padding: 4px 4px 4px 20px;
        margin: 0px 8px 8px 8px;
        border-radius: 4px;
        font-size: 14px;
      }

      .widget-backlight {
        background-color: @noti-bg;
        padding: 8px 8px 4px 8px;
        margin: 8px 8px 0px 8px;
        border-top-left-radius: 12px;
        border-top-right-radius: 12px;
      }

      .KB {
        padding: 4px 8px 4px 8px;
        margin: 0px 8px 0px 8px;
        border-radius: 0;
      }

      .widget-menubar>box{
        padding: 8px 0px 4px;
        margin: 0px 8px;
        border-radius: 4px 4px 0px 0px;
        background-color: @noti-bg;
      }

      .widget-menubar>box>.menu-button-bar>button{
        border: none;
        background: @noti-bg;
        border-radius: 4px;
        margin: 4px 12px;
      }

      .widget-buttons-grid{
        padding: 0px 8px 8px;
        margin: 0px 8px 8px;
        border-radius: 0px 0px 4px 4px;
        background: @noti-bg;
        font-size: 14px;
      }

      .widget-buttons-grid>flowbox>flowboxchild>button{
        background: @noti-bg;
        border-radius: 4px;
      }

      .widget-buttons-grid>flowbox>flowboxchild>button:hover {
        background: @noti-bg-dark;
      }

      .screenshot-buttons,
      .screencast-buttons,
      .powermode-buttons,
      .power-buttons{
        border-radius: 4px;
      }

      .screenshot-buttons>button,
      .screencast-buttons>button,
      .powermode-buttons>button,
      .power-buttons>button{
        padding: 2px 0px;
        margin: 5px 70px 3px;
        border: none;
      }

      .screenshot-buttons>button:hover,
      .screencast-buttons>button:hover,
      .powermode-buttons>button:hover,
      .power-buttons>button:hover{
        background: @noti-bg-dark;
      }
    '';
  };

  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        spacing = 5;
        layer = "top";
        position = "top";
        height = 35;

        modules-left = [
          "custom/notification"
          "hyprland/workspaces"
          "cpu"
          "memory"
          "temperature"
        ];

        modules-center = [
          "clock"
        ];

        modules-right = [
          "network"
          "bluetooth"
          "pulseaudio"
        ];

        cpu = {
          format = "{usage}%   ";
          on-click = "wezterm start --class wezterm-btop btop";
        };

        memory = {
          format = "{}%   ";
          on-click = "wezterm start --class wezterm-btop btop";
        };

        temperature = {
          format = "{temperatureC}°C {icon}";
          format-icons = [
            ""
            ""
            "󰈸"
          ];
          tooltip = false;
          on-click = "wezterm start --class wezterm-btop btop";
          "critical-threshold" = 80;
          hwmon-path = "/sys/class/hwmon/hwmon3/temp1_input";
        };

        backlight = {
          format = "{percent}% {icon}";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
          tooltip = false;
        };

        clock = {
          format = "{:%H:%M:%S  %a %b %d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          interval = 1;
        };

        network = {
          format-wifi = "   ";
          format-ethernet = "{ifname} 󰈀   ";
          tooltip-format = "{essid}";
          format-linked = "{ifname} (No IP)    ";
          format-disconnected = "⚠  ";
          on-click = "nm-connection-editor";
        };

        bluetooth = {
          format = "  ";
          format-disabled = "󰂲  ";
          format-connected = "󰂱  ";
          tooltip-format = "{controller_alias}\t{controller_address}";
          "tooltip-format-connected" = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
          "tooltip-format-enumerate-connected" = "{device_alias}\t{device_address}";
          on-click = "overskride";
        };

        pulseaudio = {
          format = "{volume}% {icon} {format_source} ";
          format-bluetooth = "{icon} {format_source}  ";
          format-bluetooth-muted = "󰝟 {icon} {format_source}  ";
          format-muted = "󰝟 {format_source}  ";
          format-source = "  ";
          format-source-muted = "   ";
          format-icons = {
            headphone = " ";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = "pavucontrol";
          on-click-right = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        };

        "custom/notification" = {
          tooltip = false;
          format = "{icon}";
          format-icons = {
            notification = " <span foreground='red'><sup></sup></span> ";
            none = "  ";
            dnd-notification = " <span foreground='red'><sup></sup></span> ";
            dnd-none = "   ";
            inhibited-notification = " <span foreground='red'><sup></sup></span> ";
            inhibited-none = "  ";
            dnd-inhibited-notification = " <span foreground='red'><sup></sup></span> ";
            dnd-inhibited-none = " ;";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
        };

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
          all-outputs = true;
        };
      };
    };

    style = ''
      * {
          border: none;
          border-radius: 0;
          min-height: 0;
          font-family: "GeistMono Nerd Font";
      }

      window#waybar {
          background-color: #333C43;
          color: #D3C6AA;
      }

      #cpu,
      #memory,
      #temperature,
      #clock,
      #network,
      #bluetooth,
      #pulseaudio,
      #custom-notification {
          font-family: "GeistMono Nerd Font";
          background-color: #333C43;
          color: #D3C6AA;
      }

      #temperature.critical {
          color: #E67E80;
      }

      #network.disconnected {
          color: #E67E80;
      }

      #pulseaudio.muted {
          color: #D699B6;
      }

      #workspaces {
          padding: 0 4px;
      }

      #workspaces button {
          padding: 0 8px;
          background-color: #333C43;
          color: #D3C6AA;
          border: none;
          font-weight: normal;
      }

      #workspaces button.active {
          color: #A7C080;
      }

      #workspaces button.urgent {
          color: #E67E80;
      }

      #workspaces button:hover {
          background-color: #3A464C;
      }
    '';
  };
}
