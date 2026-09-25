#!/bin/sh
LOG="/tmp/clockplus-sync.log"
LOCK="/tmp/clockplus-sync.lock"
CFG="/mnt/SDCARD/.userdata/tg5040/Syncthing/config/config.xml"
ST_HOME="/mnt/SDCARD/.userdata/tg5040/Syncthing/config"
ST_BIN="/mnt/SDCARD/Tools/tg5040/Syncthing.pak/bin/arm64/syncthing"
API="http://127.0.0.1:8384"
STATUS_FILE="/tmp/csync"
PARENT_PID="${PPID:-0}"
printf 'Connected: 0/2   Sync: --%%' > "$STATUS_FILE"

if ! mkdir "$LOCK" 2>/dev/null; then
    OLDPID="$(cat "$LOCK/pid" 2>/dev/null)"
    if [ -n "$OLDPID" ] && kill -0 "$OLDPID" 2>/dev/null; then
        exit 0
    fi
    rm -rf "$LOCK" 2>/dev/null || exit 0
    mkdir "$LOCK" 2>/dev/null || exit 0
fi
echo "$$" > "$LOCK/pid"
cleanup() { rm -rf "$LOCK" 2>/dev/null || true; }
trap cleanup EXIT INT TERM
: > "$LOG"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

# Wake Wi-Fi through the Brick OS when Clock is used as a sync dock.
if ! ip -4 addr show wlan0 2>/dev/null | grep -q 'inet '; then
    if [ -x /mnt/SDCARD/.system/etc/wifi/wifi_init.sh ]; then
        /mnt/SDCARD/.system/etc/wifi/wifi_init.sh start >/dev/null 2>&1 &
        log "wifi: wake requested"
    fi
fi

# Give Wi-Fi time to come up, but never block the Clock UI.
i=0
while [ "$i" -lt 20 ]; do
    if ip -4 addr show wlan0 2>/dev/null | grep -q 'inet '; then
        break
    fi
    sleep 1
    i=$((i + 1))
done
if ! ip -4 addr show wlan0 2>/dev/null | grep -q 'inet '; then
    log "wifi: no IPv4 address; sync skipped"
    exit 0
fi
IP="$(ip -4 addr show wlan0 | awk '/inet / {print $2; exit}')"
log "wifi: ready at $IP"

if [ -n "${SYSTEM_PATH:-}" ] && [ -x "$SYSTEM_PATH/bin/syncsettings.elf" ]; then
    "$SYSTEM_PATH/bin/syncsettings.elf" >/dev/null 2>&1 || true
fi

KEY="$(sed -n 's:.*<apikey>\(.*\)</apikey>.*:\1:p' "$CFG" | head -n 1)"
if [ -z "$KEY" ]; then
    log "syncthing: API key missing"
    exit 0
fi
api() { curl -s --max-time 2 -H "X-API-Key: $KEY" "$@"; }

if ! api "$API/rest/system/status" | grep -q '"myID"'; then
    if ! ps | grep "$ST_BIN serve" | grep -v grep >/dev/null 2>&1; then
        "$ST_BIN" serve --home="$ST_HOME" >>/tmp/clockplus-syncthing.log 2>&1 &
        log "syncthing: started"
    fi
    i=0
    while [ "$i" -lt 15 ]; do        api "$API/rest/system/status" | grep -q '"myID"' && break
        sleep 1
        i=$((i + 1))
    done
fi
STATUS="$(api "$API/rest/system/status")"
MYID="$(echo "$STATUS" | sed -n 's/.*"myID": "\([^"]*\)".*/\1/p' | head -n 1)"
if [ -z "$MYID" ]; then
    log "syncthing: local API unavailable"
    exit 0
fi

FOLDERS="$(grep '<folder id="brick-' "$CFG" | sed -n 's/.*id="\([^"]*\)".*/\1/p')"
scan_all() {
    for f in $FOLDERS; do
        api -X POST "$API/rest/db/scan?folder=$f" >/dev/null 2>&1 || true
    done
}
scan_all
log "syncthing: forced scan for $(echo $FOLDERS)"

PIID="$(grep 'name="PiSaveHub"' "$CFG" | sed -n 's/.*device id="\([^"]*\)".*/\1/p' | head -n 1)"
PEERID=""
for id in $(grep '<device id=.* name="' "$CFG" | sed -n 's/.*device id="\([^"]*\)".*/\1/p'); do
    [ "$id" = "$MYID" ] && continue
    [ "$id" = "$PIID" ] && continue
    PEERID="$id"
    break
done
peer_connected() {    [ -n "$PEERID" ] || return 1
    api "$API/rest/system/connections" | tr -d '\r\n ' | grep -q "\"$PEERID\":{[^}]*\"connected\":true"
}

# Tiny status feed for Clock+. Self counts as one Brick; the other Brick is the peer.
# Sync percentage is the slowest copy across this Brick, the Pi hub, and the live peer.
status_update() {
    if ! api "$API/rest/system/status" | grep -q '"myID"'; then
        line='Connected: 0/2   Sync: --%'
        printf '%s' "$line" > "$STATUS_FILE"
        return
    fi

    connected=1
    peer_live=0
    if peer_connected; then
        connected=2
        peer_live=1
    fi

    # If the other Brick is offline there is no meaningful peer-sync percentage.
    if [ "$peer_live" -ne 1 ]; then
        line='Connected: 1/2   Sync: --%'
    else
        pct=100
        busy=0
        for f in $FOLDERS; do
            js="$(api "$API/rest/db/status?folder=$f" | tr -d '\r\n ')"
            gb="$(echo "$js" | sed -n 's/.*"globalBytes":[[:space:]]*\([0-9][0-9]*\).*/\1/p')"
            nb="$(echo "$js" | sed -n 's/.*"needBytes":[[:space:]]*\([0-9][0-9]*\).*/\1/p')"
            state="$(echo "$js" | sed -n 's/.*"state":[[:space:]]*"\([^"]*\)".*/\1/p')"
            [ "$state" = "idle" ] || busy=1

            if [ -n "$gb" ] && [ -n "$nb" ]; then
                if [ "$gb" -gt 0 ]; then
                    lp=$(( (gb - nb) * 100 / gb ))
                else
                    lp=100
                fi
                [ "$lp" -lt "$pct" ] && pct="$lp"
            fi

            # Only the other Brick matters here. The Pi does not carry every folder
            # (ROMs in particular), which was why v0.3.1 falsely reported 0%.
            c="$(api "$API/rest/db/completion?device=$PEERID&folder=$f" | sed -n 's/.*"completion":[[:space:]]*\([0-9][0-9.]*\).*/\1/p')"
            c="${c%%.*}"
            [ -n "$c" ] && [ "$c" -lt "$pct" ] && pct="$c"
        done
        [ "$busy" -eq 1 ] && [ "$pct" -ge 100 ] && pct=99
        [ "$pct" -lt 0 ] && pct=0
        [ "$pct" -gt 100 ] && pct=100
        line="$(printf 'Connected: 2/2   Sync: %d%%' "$pct")"
    fi

    printf '%s' "$line" > "$STATUS_FILE"
    if [ -n "${MYID:-}" ]; then
        short="${MYID%%-*}"
        printf '%s | %s | v0.3.2 | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$short" "$line" > "/mnt/SDCARD/.userdata/shared/.clockplus-status-$short.txt"
    fi
}
status_update
i=0
while [ "$i" -lt 20 ] && ! peer_connected; do
    sleep 1
    status_update
    i=$((i + 1))
done

if peer_connected; then
    log "peer: connected; rescanning after handshake"
    scan_all
else
    log "peer: not connected; Pi/local sync still forced"
fi

all_idle() {
    for f in $FOLDERS; do
        JS="$(api "$API/rest/db/status?folder=$f" | tr -d '\r\n ')"
        echo "$JS" | grep -q '"needTotalItems":0' || return 1
        echo "$JS" | grep -q '"state":"idle"' || return 1
    done
    return 0
}
status_update
i=0
while [ "$i" -lt 30 ] && ! all_idle; do
    sleep 1
    status_update
    i=$((i + 1))
done
if all_idle; then
    log "sync: all Brick folders idle and caught up"
else
    log "sync: still settling after timeout; Syncthing continues in background"
fi
status_update

# Keep the little Clock status line live for as long as this Clock launcher exists.
while [ "$PARENT_PID" -gt 1 ] && kill -0 "$PARENT_PID" 2>/dev/null; do
    sleep 2
    status_update
done
exit 0
