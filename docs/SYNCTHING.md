# Syncthing setup

Clock+ does not install Syncthing for you. It talks to a Syncthing install that is already working on the Brick.

The helper is built around my setup: **two TrimUI Bricks**, with an optional Raspberry Pi hub for some folders.

## The simple version: two Bricks only

1. Install Syncthing on both Bricks.
2. Add Brick A as a device on Brick B, and vice versa.
3. Share the folders you want between them.
4. Give every folder Clock+ should force-scan an ID beginning with `brick-`.

Example folder IDs/paths:

| Folder ID | Example Brick path | Notes |
| --- | --- | --- |
| `brick-saves` | `/mnt/SDCARD/Saves` | Saves shared between both Bricks |
| `brick-roms` | `/mnt/SDCARD/Roms` | ROM library, if you want that synced |
| `brick-shared` | `/mnt/SDCARD/.userdata/shared` | Shared app/config data |
| `brick-tools` | `/mnt/SDCARD/Tools/tg5040` | Optional tool/package syncing |

I use `sendreceive` so either Brick can make changes.

## Optional Raspberry Pi hub

My setup also has a Pi running Syncthing. It acts as a central copy for some folders.

The Pi device is named:

`PiSaveHub`

Clock+ recognizes that name and deliberately does **not** mistake the Pi for the other Brick when it calculates `Connected: x/2`.

The Pi does not need to host every folder. Mine does not need to carry the full ROM folder, for example.

That detail matters: v0.3.1 tried to include the Pi in every folder's completion calculation and could report `Sync: 0%` even when both Bricks were actually caught up. v0.3.2 compares the Bricks directly instead.

## What Clock+ does when opened

`sync-now.sh` runs in the background so the clock itself opens immediately.

It then:

1. Checks whether `wlan0` has an IPv4 address.
2. Tries to wake Wi-Fi if it does not.
3. Reads Syncthing's local API key from its own `config.xml`.
4. Starts Syncthing if its local API is not responding.
5. Finds every Syncthing folder ID beginning with `brick-`.
6. Forces a scan on those folders.
7. Finds the other Brick (excluding itself and `PiSaveHub`).
8. Waits briefly for that Brick to connect.
9. Re-scans after the peer appears.
10. Updates `/tmp/csync` every couple seconds while Clock+ is open.

No Syncthing API key is hard-coded in this repo.

## Paths Clock+ expects

Syncthing config:

`/mnt/SDCARD/.userdata/tg5040/Syncthing/config/config.xml`

Syncthing binary:

`/mnt/SDCARD/Tools/tg5040/Syncthing.pak/bin/arm64/syncthing`

Local API:

`http://127.0.0.1:8384`

If your firmware/package uses different paths, edit the variables at the top of `Clock.pak/sync-now.sh`.

## Status math

`Connected: 2/2` means the other Brick is actually connected according to Syncthing's local connections API.

The sync percentage uses the slowest `brick-*` folder it can see between this Brick and the peer Brick.

If Syncthing is still scanning/working but byte counts look complete, Clock+ caps the display at `99%` instead of lying and saying `100%` early.

## A note about syncing settings

Do not blindly sync every random settings database/file just because you can.

Two devices writing the same settings file can create Syncthing conflicts. Saves, ROMs, and intentionally shared app data are much safer starting points.

If one specific settings file keeps generating `sync-conflict` copies, exclude it instead of pretending the conflict is useful.
