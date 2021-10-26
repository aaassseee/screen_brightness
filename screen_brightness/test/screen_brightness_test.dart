import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

const double systemBrightness = 0.5;

late StreamController<double> controller;

class MockScreenBrightnessPlatform
    with MockPlatformInterfaceMixin
    implements ScreenBrightnessPlatform {
  double _currentBrightness = systemBrightness;

  @override
  Future<double> get system => Future.value(systemBrightness);

  @override
  Future<double> get current => Future.value(_currentBrightness);

  @override
  Future<void> setScreenBrightness(double brightness) async {
    _currentBrightness = brightness;
  }

  @override
  Future<void> resetScreenBrightness() async {
    _currentBrightness = systemBrightness;
  }

  @override
  Stream<double> get onCurrentBrightnessChanged => controller.stream;
}

void main() {
  late ScreenBrightness screenBrightness;
  late MockScreenBrightnessPlatform mockScreenBrightnessPlatform;

  setUp(() {
    mockScreenBrightnessPlatform = MockScreenBrightnessPlatform();
    ScreenBrightnessPlatform.instance = mockScreenBrightnessPlatform;
    screenBrightness = ScreenBrightness();
  });

  test('get system brightess', () async {
    expect(await screenBrightness.system, systemBrightness);
  });

  test('get screen brightess', () async {
    expect(await screenBrightness.current, systemBrightness);
  });

  test('set screen brightess with valid number', () async {
    const targetBrightness = 0.1;
    await screenBrightness.setScreenBrightness(targetBrightness);
    expect(await screenBrightness.current, targetBrightness);
  });

  test('reset screen brightess', () async {
    await screenBrightness.resetScreenBrightness();
    expect(await screenBrightness.current, systemBrightness);
  });
}
