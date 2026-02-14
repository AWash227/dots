#!/usr/bin/env bash
# send “toggle” to the dictation UNIX socket via netcat
echo "toggle" | nc -U /tmp/sttdict.sock
