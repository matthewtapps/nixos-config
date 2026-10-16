#!/usr/bin/env bash

state="$HOME/.local/state/external-monitor-off"

if [ -e "$state" ]; then
    rm "$state"
    notify-send "External monitor" "On"
else
    mkdir -p "${state%/*}"
    touch "$state"
    notify-send "External monitor" "Off"
fi

hyprctl reload
