# Apium QuickLook Preview

This repository contains a macOS QuickLook implementation for ApiumSlicer `.gcode` and `.3mf` files.

## What is implemented

- Shared parser module:
  - `GCodeParser` with reverse-first 8 MB tail parsing + full-scan fallback
  - `ThreeMFParser` for `.3mf` (ZIP) using in-process archive reading
- Metadata extraction:
  - `Printer`: `printer_model` -> `printer_settings_id` -> `printer_vendor`
  - `Material Type`: `filament_type` -> `filament_settings_id`
  - `Nozzle Diameter`: `nozzle_diameter` -> numeric `printer_variant`
  - `Print Time`: only from GCODE (`estimated printing time (normal mode)` -> `estimated printing time`)
- QuickLook extensions:
  - Thumbnail provider with embedded image fallback badge rendering
  - Preview provider with English info rows and hidden `Print Time` for 3MF
- Unit tests for parser behavior.

## Project layout

- Shared code: `Sources/ApiumQuickLookShared`
- Thumbnail extension source: `Extensions/ThumbnailExtension`
- Preview extension source: `Extensions/PreviewExtension`
- Host app source: `App`
- Tests: `Tests/ApiumQuickLookSharedTests`
- XcodeGen spec for app + extension targets: `project.yml`

## Notes

- Minimum target: macOS 13.
- File scope is strict to ApiumSlicer-identifiable files.
- `Print Time` stays as raw GCODE text.
- Signing configuration is intentionally managed in Xcode project
  settings (no team IDs or signing secrets in repository scripts).

## Build

- Generate project if needed:
  - `GENERATE_XCODEPROJ=1 ./scripts/build.sh`
- Standard build (uses Xcode signing settings):
  - `./scripts/build.sh`
- Unsigned build:
  - `UNSIGNED=1 ./scripts/build.sh`
