#!/bin/sh
set -u

PAK_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
export BRICK_CLOCK_PAK_DIR="$PAK_DIR"

CONFIG_DIR="/mnt/SDCARD/.userdata/shared"
CONFIG="$CONFIG_DIR/clockplus.cfg"
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG" ]; then
cat > "$CONFIG" <<'CFG'
use_24h=0
show_date=1
show_battery=1
burnin_shift=1
CFG
fi
export BRICK_CLOCK_CONFIG="$CONFIG"

touch /tmp/stay_awake 2>/dev/null || true

# Bedside mode: keep Brick accent/charging LEDs dark.
for f in   /sys/class/led_anim/max_scale   /sys/class/led_anim/max_scale_lr   /sys/class/led_anim/max_scale_f1f2   /sys/class/led_anim/max_scale_rear
do
  if [ -e "$f" ]; then
    echo 0 > "$f" 2>/dev/null || true
  fi
done

# Clock+ force sync: verify Wi-Fi and kick all Brick Syncthing folders.
if [ -x "$PAK_DIR/sync-now.sh" ]; then
    "$PAK_DIR/sync-now.sh" >/dev/null 2>&1 &
fi

cleanup() {
    rm -f /tmp/stay_awake 2>/dev/null || true
    if [ -n "${SYSTEM_PATH:-}" ] && [ -x "$SYSTEM_PATH/bin/syncsettings.elf" ]; then
        "$SYSTEM_PATH/bin/syncsettings.elf" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT INT TERM

cd "$PAK_DIR"
"$PAK_DIR/bin/brickclock"
exit $?
