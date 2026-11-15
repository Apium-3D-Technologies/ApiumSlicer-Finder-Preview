# ApiumSlicer Finder Preview
macOS Quick Look thumbnails and previews for ApiumSlicer `.a3d` and `.gcode` files
plus `.stl` and `.obj` models. Requires macOS 13 or later.

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
(`brew install xcodegen`). 

```sh
swift test
GENERATE_XCODEPROJ=1 ./scripts/build.sh
# Build using ad-hoc Xcode signing, then install and refresh Quick Look:
GENERATE_XCODEPROJ=1 INSTALL=1 ./scripts/build.sh CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual
```


### License
`ApiumSlicer-Finder-Preview` is licensed under the [GNU Affero General Public License, version 3](LICENSE).
