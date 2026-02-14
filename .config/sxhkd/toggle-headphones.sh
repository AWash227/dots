#!/usr/bin/env bash
set -euo pipefail

# ---- CONFIG ----
VM="${VM_NAME:-ubuntu24.04}"
VIRSH="${VIRSH:-virsh -c qemu:///system}"
ATTACH_XML="${ATTACH_XML:-$HOME/.config/sxhkd/steelseries-attach.xml}"  # vendor/product XML
APP_NAME="Headset Toggle"
ICON="${ICON:-audio-headset}"  # freedesktop icon name if your theme has it
# ----------------

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "$APP_NAME" -i "$ICON" "$1" "$2"
  else
    # Fallback to stderr so you still see something
    printf '%s: %s\n' "$1" "$2" >&2
  fi
}

need() { command -v "$1" >/dev/null || { notify "Missing dependency" "$1 not found"; exit 1; }; }
need awk
need sed
$VIRSH --version >/dev/null || { notify "virsh error" "Cannot talk to system libvirt"; exit 1; }

[ -f "$ATTACH_XML" ] || { notify "Missing XML" "$ATTACH_XML not found"; exit 1; }

state="$($VIRSH domstate "$VM" | tr '[:upper:]' '[:lower:]' || true)"
[[ "$state" == "running" || "$state" == "paused" ]] || { notify "VM not running" "$VM is $state"; exit 1; }

is_attached() {
  $VIRSH dumpxml "$VM" | grep -q "<hostdev[^>]*type='usb'"
}

detach_live_exact() {
  tmp=/tmp/steelseries-detach.xml
  # Grab the first usb hostdev block from live XML; if you have multiple USB hostdevs,
  # filter by your vendor id to be precise.
  if ! $VIRSH dumpxml "$VM" \
      | sed -n "/<hostdev[^>]*type='usb'/,/<\/hostdev>/p" \
      | awk '/<hostdev/{blk=$0;next} {blk=blk ORS $0} /<\/hostdev>/{print blk; exit}' > "$tmp"; then
    notify "Detach failed" "Could not extract live USB hostdev block"
    return 1
  fi

  # Prefer cleaning live, then config (ignore benign failures)
  $VIRSH detach-device "$VM" "$tmp" --live 2>/dev/null || true
  $VIRSH detach-device "$VM" "$tmp" --config 2>/dev/null || true
  rm -f "$tmp"
}

attach_live() {
  $VIRSH attach-device "$VM" "$ATTACH_XML" --live
}

if is_attached; then
  if detach_live_exact; then
    notify "Headset detached" "Returned to host from $VM"
    exit 0
  else
    notify "Detach error" "USB still held by $VM; check domain XML"
    exit 2
  fi
else
  if attach_live; then
    notify "Headset attached" "Passed to $VM (live)"
    exit 0
  else
    notify "Attach error" "Could not pass device to $VM"
    exit 3
  fi
fi

