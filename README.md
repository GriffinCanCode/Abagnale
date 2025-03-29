# abagnale

A macOS application that adds visual effects to your MacBook camera, compatible with Zoom, Teams, and other video conferencing apps.

## Features

- Real-time camera effects using Core Image filters
- Virtual camera support for use in video conferencing apps
- Multiple built-in effects:
  - Normal
  - Sepia
  - Comic Effect
  - Color Invert
  - Thermal
  - X-Ray
  - Bloom
  - Pixellate
  - Kaleidoscope
  - Zoom Blur
  - Vignette

## Requirements

- macOS 12.0 or later
- Xcode 13.0 or later
- Swift 5.5 or later
- MacBook with built-in camera

## Installation

1. Clone this repository
2. Open Terminal and navigate to the project directory
3. Build the project:
   ```bash
   swift build
   ```
4. Run the application:
   ```bash
   swift run
   ```
5. When prompted, click "Install" to install the virtual camera driver
6. Grant camera permissions when requested

## Usage with Video Conferencing Apps

1. Launch abagnale
2. Select your desired effect from the list
3. In your video conferencing app (Zoom, Teams, etc.):
   - Go to Settings > Video > Camera
   - Select "MacBook Camera Effects"
4. If the camera doesn't appear:
   - Restart your video conferencing app
   - Check camera permissions in System Preferences > Security & Privacy > Camera
   - Quit and relaunch abagnale

## Development

To modify or add new effects:

1. Open the project in Xcode:
   ```bash
   xed .
   ```
2. Navigate to `Sources/abagnale/main.swift`
3. Add new effects in the `setEffect` method of `EffectsController`
4. Add the effect name to the `availableEffects` array

## License

This project is licensed under the MIT License - see the LICENSE file for details. 