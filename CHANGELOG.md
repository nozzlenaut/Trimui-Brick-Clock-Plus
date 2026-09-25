# Changelog

## v0.3.2

- Added visible live `Connected: x/2` and `Sync: xx%` status to the Clock screen.
- Fixed the status line being drawn in a clipped footer area where nobody could actually see it. Very useful feature there.
- Fixed false `Sync: 0%` results when a Pi hub did not host every synced folder (ROMs were the main offender).
- Sync percentage now compares the two Bricks instead of assuming every device has every folder.
- Added a small shared heartbeat file for easier remote debugging.

## v0.3.1

- Added diagnostic heartbeat output.
- Confirmed both Bricks could detect each other as `2/2`.
- Had a bad sync-percentage calculation when a Pi was present.

## v0.3.0

- First live sync-status experiment.
- Added `/tmp/csync` status feed and binary display hook.

## v0.2.3

- Clock launch could force a Syncthing scan/sync in the background.
- Wi-Fi wake and Syncthing startup handling added.

## Earlier

- Basic Clock+ behavior: bedside clock, date, battery, burn-in shift, low-brightness use.
