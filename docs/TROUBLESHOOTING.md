# Troubleshooting

## Clock+ opens, but there is no sync/status line

First make sure `sync-now.sh` is executable:

```sh
ls -l /mnt/SDCARD/Tools/tg5040/Clock.pak/sync-now.sh
```

Then check:

```sh
cat /tmp/csync
cat /tmp/clockplus-sync.log
```

If `/tmp/csync` contains a good status but nothing is drawn on screen, that is a Clock binary/rendering problem, not a Syncthing problem.

## `Connected: 1/2`

This Brick's Syncthing is alive, but the other Brick is not connected.

Check:

- both Bricks are awake;
- Wi-Fi is on;
- both devices are approved in Syncthing;
- the two Bricks can reach each other on the network;
- Syncthing is actually running on the other Brick.

## `Connected: 0/2`

The local Syncthing API is unavailable.

Look at:

```sh
cat /tmp/clockplus-sync.log
cat /tmp/clockplus-syncthing.log
```

Also verify the paths at the top of `sync-now.sh` match your Syncthing install.

## `Sync: --%`

Clock+ does not have a connected peer Brick to compare yet.

That is normal with `1/2`.

## It says `99%` forever

Syncthing may still consider one folder scanning or otherwise non-idle.

Open the Syncthing UI and inspect the `brick-*` folders, or check the local API/logs.

## It says `0%` even though everything is synced

Make sure you are on **v0.3.2 or newer**.

v0.3.1 had a dumb bug where the optional Pi hub was included in completion math for folders it did not host. ROMs made this especially obvious.

## Syncthing conflict files keep appearing

Figure out which file both Bricks are actively changing.

Do not sync device-local settings just because they happen to live in a convenient folder. Add an ignore rule for files that should stay local.

## Clock+ is too bright

Clock+ is intentionally basic right now. Screen brightness itself is still controlled by the Brick/firmware. The launcher only kills the accent/charging LED scales.

## Clock+ closes / will not start

Check that these exist:

```text
Clock.pak/bin/brickclock
Clock.pak/font.ttf
Clock.pak/launch.sh
Clock.pak/pak.json
```

and that `brickclock` + `launch.sh` are executable.

The binary is ARM64 and expects the Brick's SDL2 / SDL2_ttf / SDL2_image environment.

## Useful files

- `/tmp/clockplus-sync.log` - force-sync steps
- `/tmp/clockplus-syncthing.log` - Syncthing startup output
- `/tmp/csync` - exact status line read by the clock
- `/mnt/SDCARD/.userdata/shared/.clockplus-status-*.txt` - diagnostic heartbeat synced through shared userdata
