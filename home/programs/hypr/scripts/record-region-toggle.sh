#!/usr/bin/env bash

if pgrep -x wf-recorder > /dev/null; then
    # Stop recording
    pkill -SIGINT wf-recorder
    notify-send "Recording" "Recording stopped"
else
    # Start recording
    mkdir -p ~/recordings
    GEOMETRY=$(slurp)
    
    if [ -n "$GEOMETRY" ]; then
        FILENAME="$HOME/recordings/recording-$(date +%Y%m%d-%H%M%S).mp4"
        wf-recorder -g "$GEOMETRY" -f "$FILENAME" &
        notify-send "Recording" "Recording started"
    fi
fi
