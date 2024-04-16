import 'dart:async';

import 'package:async/async.dart';
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
  double? _changedBrightness;

  bool _isAutoReset = true;
  bool _isAnimate = true;

  @override
  Future<double> get system => Future.value(systemBrightness);

  @override
  Future<double> get current => Future.value(_currentBrightness);

  @override
  Future<void> setScreenBrightness(double brightness,
      {bool animated = true}) async {
    _currentBrightness = brightness;
    _changedBrightness = brightness;
  }

  @override
  Future<void> resetScreenBrightness() async {
    _currentBrightness = systemBrightness;
    _changedBrightness = null;
  }

  @override
  Stream<double> get onCurrentBrightnessChanged => controller.stream;

  @override
  Future<bool> get hasChanged async => _changedBrightness != null;

  @override
  Future<bool> get isAutoReset async => _isAutoReset;

  @override
  Future<void> setAutoReset(bool isAutoReset) async {
    _isAutoReset = isAutoReset;
  }

  @override
  Future<bool> get isAnimate async => _isAnimate;

  @override
  Future<void> setAnimate(bool isAnimate) async {
    _isAnimate = isAnimate;
  }
}

void main() {
  late ScreenBrightness screenBrightness;
  late MockScreenBrightnessPlatform mockScreenBrightnessPlatform;

  setUp(() {
    mockScreenBrightnessPlatform = MockScreenBrightnessPlatform();
    ScreenBrightnessPlatform.instance = mockScreenBrightnessPlatform;
    screenBrightness = ScreenBrightness.instance;
  });

  test('get system brightness', () async {
    expect(await screenBrightness.system, systemBrightness);
  });

  test('get screen brightness', () async {
    expect(await screenBrightness.current, systemBrightness);
  });

  test('set screen brightness with valid number', () async {
    const targetBrightness = 0.1;
    await screenBrightness.setScreenBrightness(targetBrightness);
    expect(await screenBrightness.current, targetBrightness);
  });

  test('reset screen brightness', () async {
    await screenBrightness.resetScreenBrightness();
    expect(await screenBrightness.current, systemBrightness);
  });

  group('on screen brightness changed stream', () {
    setUp(() {
      controller = StreamController<double>();
    });

    tearDown(() {
      controller.close();
    });

    test('receive values', () async {
      final queue =
          StreamQueue<double>(screenBrightness.onCurrentBrightnessChanged);

      controller.add(0.2);
      expect(await queue.next, 0.2);

      controller.add(systemBrightness);
      expect(await queue.next, systemBrightness);

      controller.add(0);
      expect(await queue.next, 0);

      controller.add(1);
      expect(await queue.next, 1);
    });
  });

  test('has changed', () async {
    expect(await screenBrightness.hasChanged, false);

    await screenBrightness.setScreenBrightness(0.1);
    expect(await screenBrightness.hasChanged, true);

    await screenBrightness.setScreenBrightness(systemBrightness);
    expect(await screenBrightness.hasChanged, true);

    await screenBrightness.resetScreenBrightness();
    expect(await screenBrightness.hasChanged, false);
  });

  test('is auto reset', () async {
    expect(await screenBrightness.isAutoReset, true);

    await screenBrightness.setAutoReset(false);
    expect(await screenBrightness.isAutoReset, false);

    await screenBrightness.setAutoReset(true);
    expect(await screenBrightness.isAutoReset, true);
  });

  test('is animate', () async {
    expect(await screenBrightness.isAnimate, true);

    await screenBrightness.setAnimate(false);
    expect(await screenBrightness.isAnimate, false);

    await screenBrightness.setAnimate(true);
    expect(await screenBrightness.isAnimate, true);
  });
}
