# screen_brightness

A Plugin for controlling screen brightness with application life cycle set and reset brightness implemented

## Getting Started
### Install
Add the following lines in your pubspec.yaml file

```yaml
  screen_brightness: ^latest_version
```

latest_version:\
[![pub package](https://img.shields.io/pub/v/screen_brightness.svg)](https://pub.dartlang.org/packages/screen_brightness)

### API
#### Initial brightness
```dart
Future<double> get initialBrightness async {
  try {
    return await ScreenBrightness.initial;
  } catch (e) {
    print(e);
    throw 'Failed to get initial brightness';
  }
}
```
#### Current brightness
```dart
Future<double> get currentBrightness async {
  try {
    return await ScreenBrightness.current;
  } catch (e) {
    print(e);
    throw 'Failed to get current brightness';
  }
}
```
#### Set brightness
```dart
Future<void> setBrightness(double brightness) async {
  try {
    await ScreenBrightness.setScreenBrightness(brightness);
  } catch (e) {
    print(e);
    throw 'Failed to set brightness';
  }
}
```
#### reset brightness
```dart
Future<void> resetBrightness() async {
  try {
    await ScreenBrightness.resetScreenBrightness();
  } catch (e) {
    print(e);
    throw 'Failed to reset brightness';
  }
}
```

### Usage

* DON'T use didChangeAppLifecycleState to set or reset brightness because this plugin already implemented this function.
* You may also use this plugin with [wakelock](https://pub.dev/packages/wakelock) to prevent screen sleep

## Maintainer

[Jack Liu](https://github.com/aaassseee)