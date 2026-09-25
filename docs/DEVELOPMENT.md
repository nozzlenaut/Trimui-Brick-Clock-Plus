# Development notes

This file exists because the current Clock+ works, but part of how it works is objectively weird and I do not want to rediscover it later.

## Current state

`Clock.pak/bin/brickclock` is a compiled **AArch64 / ARM64 ELF** executable.

It dynamically links against the libraries already present on the Brick, including SDL2, SDL2_ttf and SDL2_image.

The binary still contains debug/symbol information and references `main.c`, but the original C source used to build this exact binary has **not been recovered**.

That means v0.3.x should be treated as a known-good binary baseline, not as a nice clean source build.

## Why there is a binary patch

The original clock already drew the time/date/battery correctly. I wanted one extra line:

`Connected: 2/2   Sync: 100%`

Rather than replace the whole clock with an untested rewrite, v0.3.x adds a tiny hook immediately before the existing screen-present call.

The helper script writes the text to:

`/tmp/csync`

The patched binary reads that file and draws the line using the clock's existing SDL renderer/font path.

## Patch landmarks

These addresses are from the current known-good binary and are here for reference, not as a promise that they will apply to a future rebuild.

- original `ap_present` call in `main`: `0x402df4`
- injected hook: `0x40dd04`
- existing `draw_center`: `0x403900`
- existing `ap_present`: `0x4061f0`
- `fopen@plt`: `0x402360`
- `fclose@plt`: `0x402340`
- `fgets@plt`: `0x402870`

The first executable LOAD segment originally ended at `0xdd04`. There was unused padding before the next segment, so the executable segment was extended to `0xdd98` and the small hook was placed in that padding instead of growing/repacking the whole ELF.

## v0.3.0 -> v0.3.2 lesson

The first display hook technically ran, but I put the status line in a clipped footer area. So SDL happily drew the thing where I could not see it. Great success.

v0.3.2 moves it into the visible clock canvas and uses a more readable font size.

The sync helper also changed in v0.3.2 so the optional Pi hub is not included in completion math for folders the Pi does not host.

## Current binary hashes

Known-good v0.3.2 files from the working two-Brick setup:

```text
brickclock
SHA256 502ba3ab793c7da2272a5603e85084b6c1c2d1cec9ee1bca0bd42bd7c5ca6b13

font.ttf
SHA256 73ef11880b9f72ef5b3bf26a7d35a19b4865fa4452aa535accb688fb07c69515
```

If the checked-in binary changes unexpectedly, stop and figure out why before calling it the same release.

## Shell side

`launch.sh` is intentionally boring:

- create/load config;
- keep the Brick awake;
- kill bright LEDs;
- optionally start `sync-now.sh`;
- run `brickclock`;
- clean up on exit.

`sync-now.sh` is where the network logic lives. It talks only to Syncthing's local API and reads the API key from Syncthing's own config file.

The sync helper only force-scans folder IDs beginning with `brick-`. Keep that convention unless there is a good reason to change it.

## What I would do next

The sane long-term move is to get the clock core back into real source form instead of stacking more binary patches on it.

Good future targets:

1. Rebuild/rewrite the current Clock UI in C/SDL from source.
2. Keep the same `clockplus.cfg` format so upgrades do not trash user settings.
3. Keep `/tmp/csync` as a simple boundary between UI and sync logic unless there is a reason not to.
4. Add proper launcher config switches for sync-on-open, LED behavior, keep-awake and sync-status visibility.
5. Package releases so a normal user can copy one `Clock.pak` folder and be done.

Until then, the checked-in v0.3.2 binary is the baseline that is actually tested on hardware.
