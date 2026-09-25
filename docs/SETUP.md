# Setup

This is the boring, repeatable setup. That is intentional.

## 1. Copy the package

Copy the entire `Clock.pak` folder to:

`/mnt/SDCARD/Tools/tg5040/Clock.pak`

Do not copy only the binary. The launcher, font and metadata are all part of the package.

## 2. Make the executables executable

From SSH/terminal on the Brick:

```sh
chmod +x /mnt/SDCARD/Tools/tg5040/Clock.pak/launch.sh
chmod +x /mnt/SDCARD/Tools/tg5040/Clock.pak/bin/brickclock
```

If you want Syncthing integration too:

```sh
chmod +x /mnt/SDCARD/Tools/tg5040/Clock.pak/sync-now.sh
```

If you only want a clock, leave `sync-now.sh` non-executable. The launcher checks before running it.

## 3. Launch Clock+

Open Clock+ from the Tools menu.

On first run it creates:

`/mnt/SDCARD/.userdata/shared/clockplus.cfg`

Default config:

```ini
use_24h=0
show_date=1
show_battery=1
burnin_shift=1
```

Edit that file and reopen Clock+ after changing it.

## 4. Bedside behavior

While Clock+ is open, `launch.sh` does two intentional things:

- creates `/tmp/stay_awake` so the Brick does not go to sleep;
- turns the Brick's accent/charging LED scales down to zero.

When Clock+ closes, the stay-awake file is removed and the Brick's normal settings helper is called.

If you do not want one of those behaviors, see `CONFIGURATION.md`.

## 5. Optional: Syncthing

For the live connection/sync line, install and configure Syncthing first, then read `SYNCTHING.md`.

The important rule is simple: folders Clock+ should force-scan need Syncthing folder IDs that start with `brick-`.

Examples:

- `brick-saves`
- `brick-roms`
- `brick-shared`
- `brick-tools`

The actual paths can be whatever makes sense for your setup.

## Updating

Replace the `Clock.pak` folder with the newer version, keeping a copy of your old one until you know the new one works.

Your user config is outside the package at:

`/mnt/SDCARD/.userdata/shared/clockplus.cfg`

so replacing the package should not wipe your clock preferences.
