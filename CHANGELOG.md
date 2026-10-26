
# Changelog

All notable changes to **Tactical GPS** (also called Tactical Compass and GPS) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Project README and this changelog.

### Changed
- Renamed the app from "Tactical GPS" to "Tactical Compass and GPS" (2026-10-17).
- Gathered all project files into one folder with a standard layout: `src/app` (Flutter project), `src/prototype` (HTML prototypes), `docs`, `releases` (APKs) and `versions` (older builds) (2026-10-17).

### Planned
- Show the new app name inside the app and prototype.
- Show waypoints on the main compass screen.
- Replace the address bar with current location.
- Barometric and radar altitude (above sea level and above ground level).
- Improve positional accuracy beyond ±44 m.
- Distance units (ft, mi, km) and a recalibrate button.
- Location history, saved markers (pins) and an emergency signal button.

## [0.1.0] - 2026-05-01

### Added
- Interactive HTML prototype (Catppuccin Mocha theme) with an animated compass rose and heading readout.
- Position cards for MGRS grid, elevation (ft/m), latitude, longitude and street address.
- GPS accuracy badge and a "Keep screen on" toggle.
- Navigation screen: set a destination by address, latitude/longitude or MGRS; a destination arrow shows bearing and distance.
- Flutter/Android project (`tactical_compass`) using the `flutter_compass` plugin.

### Known issues
- Prototype uses simulated GPS data.
- Android build reports roughly ±44 m accuracy.

## [0.1.0-android] - 2026-05-08

### Added
- Android build `app-release_2026-05-08.apk` (attached to the GitHub release v0.1.0).

## Prototype v2 - 2026-10-04

### Changed
- Rebuilt the HTML prototype as a single screen: compass, target, coordinates, altitude, address and waypoints all visible at once.
- Waypoints plot on the compass rose at their true bearing; tapping one sets it as the target.
- Address card shows the live current location via reverse geocoding.
- Altitude: MSL from GPS, AGL computed against topographic ground elevation.
- Accuracy: Kalman filter plus rejection of fixes worse than 150 m; badge turns green, yellow or red by accuracy.

## 2026-10-26 - Published on GitHub

### Changed
- Renamed the GitHub repo from `tactical-compass` to `tacticalGPS` and made it public.
- One copy of the app only: the newest Flutter source (2026-05-08 commit) at the repo root, plus the newest prototype (`prototype/tactical_gps_v2.html`). Older Flutter versions and the first prototype stay in the private Drive archive.
- Replaced the Flutter starter README with a project README and screenshot.

### Security
- Address and coordinates blanked out in `docs/screenshot.png` before publishing.
