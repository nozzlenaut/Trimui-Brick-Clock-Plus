# Configuration

Clock+ currently has two kinds of options: normal clock settings and launcher behavior.

## Normal clock settings

File:

`/mnt/SDCARD/.userdata/shared/clockplus.cfg`

### `use_24h`

- `0` = 12-hour clock
- `1` = 24-hour clock

### `show_date`

- `0` = hide date
- `1` = show date

### `show_battery`

- `0` = hide battery info
- `1` = show battery info

### `burnin_shift`

- `0` = keep the clock in one exact position
- `1` = slightly move the rendered clock over time

I leave this on. It is cheap insurance for a screen that may sit on the same clock face for hours.

## Enable / disable Syncthing-on-open

The current launcher uses a deliberately dumb/simple switch: it runs `sync-now.sh` only if the script is executable.

Enable it:

```sh
chmod +x /mnt/SDCARD/Tools/tg5040/Clock.pak/sync-now.sh
```

Disable it:

```sh
chmod -x /mnt/SDCARD/Tools/tg5040/Clock.pak/sync-now.sh
rm -f /tmp/csync
```

That turns Clock+ back into just a clock.

## Disable the dark-LED behavior

In `Clock.pak/launch.sh`, remove or comment out the block under:

`# Bedside mode: keep Brick accent/charging LEDs dark.`

That block only writes `0` to the LED scale files when they exist.

## Disable keep-awake

In `Clock.pak/launch.sh`, remove/comment:

```sh
touch /tmp/stay_awake 2>/dev/null || true
```

and the matching cleanup line:

```sh
rm -f /tmp/stay_awake 2>/dev/null || true
```

I would not do this for bedside use, because the whole point is that the clock stays visible.

## Disable only the live sync line

Right now the live line is tied to `sync-now.sh` because that script writes `/tmp/csync` and the binary reads it.

The clean supported choice today is either:

- sync enabled + status line enabled; or
- sync disabled + no status line.

A separate `show_sync_status=` config switch would be a reasonable future cleanup.
