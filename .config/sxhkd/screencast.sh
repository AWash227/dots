#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# -------------------- CONFIG --------------------
MIC_PATTERN="${MIC_PATTERN:-SteelSeries Arctis Nova 5 Mono}"   # regex (case-insensitive)
MIC_NAME="${MIC_NAME:-}"                                       # exact source name overrides pattern
ALLOW_DEFAULT_FALLBACK="${ALLOW_DEFAULT_FALLBACK:-1}"          # 1=yes, 0=no
OUT_DIR="${OUT_DIR:-$HOME/Videos/screencasts}"
FRAMERATE="${FRAMERATE:-60}"
CRF="${CRF:-23}"
PRESET="${PRESET:-veryfast}"

PIDFILE="/tmp/screencast_ffmpeg.pid"
OUTFILE_META="/tmp/screencast_ffmpeg.out"

# -------------------- UTILS ---------------------
notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Screencast" "$*"
  else
    printf 'Screencast: %s\n' "$*" >&2
  fi
}

require() {
  for c in "$@"; do
    if ! command -v "$c" >/dev/null 2>&1; then
      notify "Missing required command: $c"
      exit 1
    fi
  done
}

is_running() {
  if [ -f "$PIDFILE" ]; then
    pid="$(cat "$PIDFILE")"
    if ps -p "$pid" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

copy_to_clipboard() {
  # $1 absolute path
  path="$1"
  uri="$(python3 - <<'PY' "$path" 2>/dev/null || true
import pathlib,sys
try:
  print(pathlib.Path(sys.argv[1]).resolve().as_uri())
except Exception:
  pass
PY
)"
  if [ -z "${uri:-}" ]; then
    uri="file://$path"
  fi

  if command -v xclip >/dev/null 2>&1; then
    printf '%s\n' "$uri"  | xclip -selection clipboard -t text/uri-list -i
    printf '%s\n' "$path" | xclip -selection clipboard -t text/plain    -i
    return 0
  fi
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s\n' "$uri"  | wl-copy --type text/uri-list
    printf '%s\n' "$path" | wl-copy --primary --type text/plain
    return 0
  fi
  notify "No clipboard tool (xclip/wl-copy) found; couldn’t place path in clipboard."
  return 1
}

get_default_source_name() {
  pactl info | awk -F': ' '/^Default Source:/{print $2; exit}'
}

# --------- SOURCE DISCOVERY (JSON first) --------
find_source_json() {
  # stdout: name|desc|mute  (empty on failure)
  src_json="$(pactl -f json list sources 2>/dev/null || true)"
  if [ -z "$src_json" ]; then
    return 1
  fi

  if [ -n "$MIC_NAME" ]; then
    line="$(jq -r --arg n "$MIC_NAME" '
      .[] | select(.name == $n)
      | "\(.name)|\(.properties."device.description" // .description // "unknown")|\(.mute // "unknown")"
    ' <<<"$src_json" | head -n1)"
    if [ -n "${line:-}" ]; then
      printf '%s\n' "$line"
      return 0
    fi
    return 1
  fi

  if [ -n "$MIC_PATTERN" ]; then
    line="$(jq -r --arg re "$MIC_PATTERN" '
      .[]
      | select( (.properties."device.description" // .description // "") | test($re; "i")
                or (.name | test($re; "i")) )
      | "\(.name)|\(.properties."device.description" // .description // "unknown")|\(.mute // "unknown")"
    ' <<<"$src_json" | head -n1)"
    if [ -n "${line:-}" ]; then
      printf '%s\n' "$line"
      return 0
    fi
  fi

  if [ "${ALLOW_DEFAULT_FALLBACK}" = "1" ]; then
    def="$(get_default_source_name || true)"
    if [ -n "${def:-}" ]; then
      line="$(jq -r --arg n "$def" '
        .[] | select(.name == $n)
        | "\(.name)|\(.properties."device.description" // .description // "unknown")|\(.mute // "unknown")"
      ' <<<"$src_json" | head -n1)"
      if [ -n "${line:-}" ]; then
        printf '%s\n' "$line"
        return 0
      fi
    fi
  fi

  return 1
}

# -------------- TEXT fallback ---------------
find_source_text() {
  # stdout: name|desc|mute  (empty on failure)
  all="$(pactl list sources 2>/dev/null || true)"
  if [ -z "$all" ]; then
    return 1
  fi

  block=""
  if [ -n "$MIC_NAME" ]; then
    block="$(awk -v RS='' -v IGNORECASE=1 -v n="$MIC_NAME" '
      /^Source #/ && $0 ~ ("[[:space:]]Name:[[:space:]]*" n "[[:space:]]*$") { print; exit }
    ' <<<"$all")"
  elif [ -n "$MIC_PATTERN" ]; then
    block="$(awk -v RS='' -v IGNORECASE=1 -v pat="$MIC_PATTERN" '
      /^Source #/ && ($0 ~ /[[:space:]]Description:[^\n]*/ || $0 ~ /device\.description/) && $0 ~ pat { print; exit }
    ' <<<"$all")"
  elif [ "${ALLOW_DEFAULT_FALLBACK}" = "1" ]; then
    def="$(get_default_source_name || true)"
    if [ -n "${def:-}" ]; then
      block="$(awk -v RS='' -v n="$def" '
        /^Source #/ && $0 ~ ("Name:[[:space:]]*" n) { print; exit }
      ' <<<"$all")"
    fi
  fi

  if [ -z "${block:-}" ]; then
    return 1
  fi

  name="$(awk -F':[[:space:]]+' '/^[[:space:]]*Name:/{print $2; exit}' <<<"$block")"
  desc="$(awk -F':[[:space:]]+' '/^[[:space:]]*Description:/{print $2; exit}' <<<"$block")"
  # mute="$(awk -F':[[:space:]]+' '/^[[:space:]]*Mute:/{print tolower($2); exit}' <<<"$block")"

  if [ -z "${name:-}" ]; then
    return 1
  fi
  if [ -z "${desc:-}" ]; then
    desc="unknown"
  fi

  printf '%s|%s\n' "$name" "$desc"
}

resolve_source() {
  require pactl
  # try JSON+jq first
  if command -v jq >/dev/null 2>&1; then
    if line="$(find_source_json)"; then
      printf '%s\n' "$line"
      return 0
    fi
  fi
  # fallback to text
  if line="$(find_source_text)"; then
    printf '%s\n' "$line"
    return 0
  fi
  return 1
}

detect_size() {
  if command -v xdpyinfo >/dev/null 2>&1; then
    size="$(xdpyinfo | awk '/dimensions:/{print $2; exit}')"
    if [ -n "${size:-}" ]; then
      printf '%s\n' "$size"
      return 0
    fi
  fi
  if command -v xrandr >/dev/null 2>&1; then
    size="$(xrandr | awk '/\*/{print $1; exit}')"
    if [ -n "${size:-}" ]; then
      printf '%s\n' "$size"
      return 0
    fi
  fi
  return 1
}

# -------------------- TOGGLE -------------------
stop_recording() {
  if [ -f "$PIDFILE" ]; then
    pid="$(cat "$PIDFILE")"
    kill -INT "$pid" 2>/dev/null || true
    # wait up to ~5s
    i=0
    while kill -0 "$pid" 2>/dev/null; do
      i=$((i+1))
      if [ "$i" -gt 100 ]; then
        break
      fi
      sleep 0.05
    done
    rm -f "$PIDFILE"
  fi

  if [ -f "$OUTFILE_META" ]; then
    f="$(cat "$OUTFILE_META")"
    rm -f "$OUTFILE_META"
    if [ -n "${f:-}" ] && [ -f "$f" ]; then
      if copy_to_clipboard "$f"; then
        notify "Stopped. Copied path to clipboard:\n$f"
      else
        notify "Stopped. File saved:\n$f"
      fi
      exit 0
    fi
  fi
  notify "Stopped recording."
  exit 0
}

start_recording() {
  require ffmpeg
  if [ -z "${DISPLAY:-}" ]; then
    notify "\$DISPLAY not set (X11)."
    exit 1
  fi

  mkdir -p "$OUT_DIR"
  stamp="$(date +'%Y-%m-%d_%H-%M-%S')"
  out_file="${OUT_DIR}/screencast_${stamp}.mp4"
  printf '%s' "$out_file" > "$OUTFILE_META"

  if ! size="$(detect_size)"; then
    notify "Failed to detect screen size."
    exit 1
  fi

  if ! resolved="$(resolve_source)"; then
    if [ -n "$MIC_NAME" ] || [ -n "$MIC_PATTERN" ]; then
      notify "Mic not found (name='${MIC_NAME:-}' pattern='${MIC_PATTERN:-}')."
    else
      notify "Mic not found and no default available."
    fi
    exit 1
  fi

  name="${resolved%%|*}"; rest="${resolved#*|}"
  desc="${rest%%|*}"

  # treat unknown as not ok

  ffmpeg -y \
    -video_size "$size" -framerate "$FRAMERATE" -f x11grab -i "$DISPLAY" \
    -f pulse -i "$name" \
    -c:v libx264 -preset "$PRESET" -crf "$CRF" -pix_fmt yuv420p \
    -c:a aac -b:a 192k \
    "$out_file" \
    >/dev/null 2>&1 &

  echo $! > "$PIDFILE"
  notify "Recording started:\n${out_file}\nAudio: ${desc} (${name})"
}

# -------------------- MAIN ---------------------
# pactl info | grep -E 'Server Name|Server String|Default Source' >&2

if is_running; then
  stop_recording
else
  start_recording
fi
