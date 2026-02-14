#!/bin/bash
# Helper to show current default audio output device
CURRENT_SINK=$(pactl get-default-sink)
SINK_DESC=$(pactl list sinks | grep -A 1 "Name: $CURRENT_SINK" | grep "Description:" | cut -d: -f2 | xargs)
notify-send -a "audio-output" -u low -t 2000 "Audio Output" "$SINK_DESC"
