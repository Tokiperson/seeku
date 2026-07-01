# Flutter cross-platform icon pack

This package was generated directly from the supplied logo bitmap without redrawing or changing the design.

## Included

- `master_logo_original_1254.png`: original uploaded logo
- `master_logo_1024.png`: 1024 px master app icon
- `flutter_project/android/app/src/main/res/mipmap-*/ic_launcher.png`
- `flutter_project/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- `flutter_project/web/favicon.png`
- `flutter_project/web/icons/Icon-192.png`
- `flutter_project/web/icons/Icon-512.png`
- `flutter_project/web/icons/Icon-maskable-192.png`
- `flutter_project/web/icons/Icon-maskable-512.png`
- `flutter_project/windows/runner/resources/app_icon.ico`
- Standalone folders: `android/`, `ios/`, `web/`, `windows/`

## Use in Flutter

Copy the corresponding folders under `flutter_project/` into the same paths in your Flutter project, replacing the existing app icon files.

For iOS, the generated PNGs are flattened to an opaque white background because App Store app icons should not contain transparency.

For Android, actual launcher display may still be clipped by the device launcher mask. The bitmap itself is unchanged from the supplied design.
