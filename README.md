# TrimUI Brick Clock+

I wanted a low-brightness bedside clock on the TrimUI Brick. Then I wanted opening the clock to force my two Bricks to sync. Then I wanted the clock to actually tell me whether that sync worked instead of making me go check Syncthing like an animal.

So this is Clock+.

Current version: **v0.3.2**

## What it does

- Big, low-brightness clock made for the TrimUI Brick.
- Optional date and battery display.
- Optional 12-hour or 24-hour time.
- Small burn-in shift so the same pixels are not lit forever.
- Keeps the Brick awake while the clock is open.
- Turns the bright accent/charging LEDs down for bedside use.
- If Syncthing is installed, opening Clock+ can wake Wi-Fi and force a sync.
- Shows live Brick-to-Brick status like `Connected: 2/2   Sync: 100%`.
- Does **not** require Syncthing if you only want the clock.

## Why the sync part exists

I have two Bricks. The idea is that I can come home, put them on chargers, open Clock+ on both, and know ROMs/saves/shared stuff are being pushed around without digging through menus.

For my setup, opening Clock+ is basically the **"sync the damn things"** button.

## Quick install

1. Download or clone this repo.
2. Copy the entire `Clock.pak` folder to:

   `/mnt/SDCARD/Tools/tg5040/Clock.pak`

3. Make sure these are executable:

   `Clock.pak/launch.sh`

   `Clock.pak/sync-now.sh` (only needed if you want Syncthing integration)

   `Clock.pak/bin/brickclock`

4. Open **Clock+** from Tools.

The first launch creates:

`/mnt/SDCARD/.userdata/shared/clockplus.cfg`

See [docs/SETUP.md](docs/SETUP.md) for the full setup.

## Status line

With Syncthing integration enabled, Clock+ shows:

- `Connected: 0/2` - local Syncthing is not available.
- `Connected: 1/2` - this Brick is up, but the other Brick is not connected.
- `Connected: 2/2` - both Bricks can see each other.
- `Sync: --%` - there is no useful peer sync percentage yet.
- `Sync: 99%` - files may be caught up, but Syncthing is still scanning/working.
- `Sync: 100%` - both Bricks are caught up for the `brick-*` folders Clock+ watches.

## Syncthing is optional

Clock+ itself does not need Syncthing.

The launcher only starts `sync-now.sh` if that file exists **and is executable**. If you do not want auto-sync, see [docs/CONFIGURATION.md](docs/CONFIGURATION.md).

The Syncthing setup I use is documented in [docs/SYNCTHING.md](docs/SYNCTHING.md). It works with two Bricks directly, and it can also use a Raspberry Pi as a hub for some folders.

## Configuration

The normal clock options live in:

`/mnt/SDCARD/.userdata/shared/clockplus.cfg`

Example:

```ini
use_24h=0
show_date=1
show_battery=1
burnin_shift=1
```

Full explanation: [docs/CONFIGURATION.md](docs/CONFIGURATION.md)

## Important development note

The current `brickclock` core is a **compiled ARM64 binary**. I do not currently have the original C source that produced it.

The live sync-status line in v0.3.x was added with a small, controlled binary patch to the existing Clock binary. That is not how I want to build this forever, but it is the version that is actually running and tested right now.

I wrote down the ugly details in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) so Future Me does not have to rediscover all of this from scratch.

## Logs / debugging

Clock+ keeps the useful temporary logs here:

- `/tmp/clockplus-sync.log`
- `/tmp/clockplus-syncthing.log`
- `/tmp/csync` - the one-line status the clock reads

There is also a tiny heartbeat file in the shared userdata folder when sync is active. See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Folder layout

```text
Clock.pak/
  bin/brickclock      ARM64 clock binary
  font.ttf            Rounded M+ Nerd Font used by the clock
  launch.sh           Clock launcher / bedside behavior
  pak.json            TrimUI tool metadata
  sync-now.sh         Optional Syncthing force-sync helper
  OFL-FONT.txt        Font license

docs/
  SETUP.md
  SYNCTHING.md
  CONFIGURATION.md
  TROUBLESHOOTING.md
  DEVELOPMENT.md
```

## Tested setup

This repo is based on the setup I am actually using:

- TrimUI Brick / `tg5040`
- Two Brick handhelds
- Syncthing v2.x on both
- Optional Raspberry Pi hub

If you are using a different firmware/layout, paths may need to change. I would rather say that than pretend this has been tested on every Brick setup on earth. lol.
