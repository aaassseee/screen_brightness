import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double brightness = 0;

  @override
  void initState() {
    super.initState();
    initScreenBrightness();
  }

  Future<void> initScreenBrightness() async {
    double _brightness;

    try {
      _brightness = await ScreenBrightness.initial;
    } catch (e) {
      print(e);
      throw 'Failed to get initial brightness';
    }

    if (!mounted) return;

    setState(() {
      brightness = _brightness;
    });
  }

  Future<void> setBrightness(double brightness) async {
    try {
      await ScreenBrightness.setScreenBrightness(brightness);
    } catch (e) {
      print(e);
      throw 'Failed to set brightness';
    }
  }

  Future<void> resetBrightness() async {
    try {
      await ScreenBrightness.resetScreenBrightness();
    } catch (e) {
      print(e);
      throw 'Failed to reset brightness';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current brightness: $brightness'),
              Slider.adaptive(
                value: brightness,
                onChanged: (value) async {
                  await setBrightness(value);
                  setState(() {
                    brightness = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  await resetBrightness();
                  await initScreenBrightness();
                },
                child: Text('reset brightness'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
