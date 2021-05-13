# screen_brightness

A Plugin for controlling screen brightness with application life cycle set and reset brightness implemented

## Getting Started
### Install
Add the following lines in your pubspec.yaml file

```yaml
  screen_brightness: ^latest_version
```

latest_version:[![pub package](https://img.shields.io/pub/v/screen_brightness.svg)](https://pub.dartlang.org/packages/screen_brightness)

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

###Usage

* DON'T use didChangeAppLifecycleState to set or reset brightness because this plugin already implemented this function.

##Maintainer

[Jack Liu](https://github.com/aaassseee)

## LICENSE


    MIT License

    Copyright (c) 2021 Jack Liu

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    
    
    
    
    
    

    

    
    
    
    
    
