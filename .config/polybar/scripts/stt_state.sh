#!/usr/bin/env bash

STATE_FILE=/tmp/sttdict.state

if [[ -f "$STATE_FILE" ]]; then
    state=$(<"$STATE_FILE")
else
    state=off
fi

if [[ "$state" == "on" ]]; then
    echo "🎙 ON"
else
    echo "🎙 off"
fi

