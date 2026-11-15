# ApiumSlicer Finder Preview

macOS Quick Look thumbnails and previews for ApiumSlicer `.gcode` and `.a3d`
projects, plus `.stl` and `.obj` models. Existing `.3mf` preview support is
retained. Requires macOS 13 or later.

- G-code/A3D: embedded images, printer, material, nozzle, temperatures, layer
  height, perimeters, infill and print time (G-code only).
- A3D: highest numeric project tag from `Metadata/.git`, including packed refs.
- STL/OBJ: transparent mesh render, dimensions, vertex/face/triangle counts
  and file size. OBJ polygons and negative indices are supported; materials
  and textures are not loaded. Dimensions assume millimetres.
- Registration offers the host as an alternate viewer without claiming default
  ownership of public model formats. macOS chooses the active Quick Look provider.

## Development

Install full Xcode, select it with `xcode-select`, and install XcodeGen
(`brew install xcodegen`). Command Line Tools alone do not include XCTest or
support `xcodebuild` for the host app.

```sh
swift test
GENERATE_XCODEPROJ=1 ./scripts/build.sh
# Build using ad-hoc Xcode signing, then install and refresh Quick Look:
GENERATE_XCODEPROJ=1 INSTALL=1 ./scripts/build.sh CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual
```

`./scripts/register.sh [source.app]` installs to
`~/Applications/ApiumQuickLookHost.app`; override with `INSTALL_PATH`.
`./scripts/unregister.sh [installed.app]` unregisters the app without deleting it.
Enable the Quick Look extensions in System Settings if needed.

## CI and releases

Pull requests and branch pushes run parser/renderer tests, generate the Xcode
project, and build/package a universal app with both extensions. Every pushed
tag runs the same checks and publishes a GitHub Release with:

- `ApiumSlicerFinderPreview-macos-universal.zip` (app, README and license)
- `SHA256SUMS.txt`

Stable `vX.Y.Z` / `X.Y.Z` tags become regular releases; other tags become
prereleases and do not replace the latest stable release. Assets are uploaded
to a draft before publication; a failed upload can be retried. Published
releases are never overwritten.

```sh
CONFIGURATION=Release GENERATE_XCODEPROJ=1 UNSIGNED=1 UNIVERSAL=1 ./scripts/build.sh
./scripts/package-release.sh
```

Release bundles carry **ad-hoc signatures**, not Developer ID signatures or
Apple notarization. They are development/integration artifacts; downloaded
apps can be blocked by Gatekeeper. Public frictionless distribution requires
Apple signing credentials and a notarization step. GPG commit signing is
independent of Apple app signing.

For downstream Slicer CI, pin a release tag and verify its checksum before
extracting the ZIP (replace `vX.Y.Z` with a published tag):

```sh
tag=vX.Y.Z
base="https://github.com/Apium-3D-Technologies/ApiumSlicer-Finder-Preview/releases/download/$tag"
curl --fail --location --remote-name "$base/ApiumSlicerFinderPreview-macos-universal.zip"
curl --fail --location --remote-name "$base/SHA256SUMS.txt"
shasum -a 256 -c SHA256SUMS.txt
ditto -x -k ApiumSlicerFinderPreview-macos-universal.zip ./finder-preview
```

## Implementation

Shared Swift parsers and the CPU renderer live in `Sources/ApiumQuickLookShared`;
SwiftUI previews and thumbnail providers are in `Extensions`. `project.yml` is
the source of truth for the generated (untracked) Xcode project. Tests include
tiny tracked fixtures and do not depend on the local `example/` directory.

G-code reads start with a 64 KiB footer, grow to at most 8 MiB, and read at most
1 MiB of legacy header data. Missing fields/images never trigger a full scan.
ZIP readers bound each extracted entry to 64 MiB and reject malformed bounds,
encrypted entries and ZIP64. Mesh inputs are limited to 256 MiB and one million
triangles.

Ported from [Explorer Preview](https://github.com/Apium-3D-Technologies/ApiumSlicer-Explorer-Preview)
at `c03792f6ecf9`, using native Finder registration and macOS packaging.
See [LICENSE](LICENSE) for the GNU GPLv3 license.
