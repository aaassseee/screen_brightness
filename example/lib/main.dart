import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    } on PlatformException {
      throw 'Failed to get screen brightness';
    }

    if (!mounted) return;

    setState(() {
      brightness = _brightness;
    });
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
                onChanged: (value) {
                  ScreenBrightness.setScreenBrightness(value);
                  setState(() {
                    brightness = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  await ScreenBrightness.resetScreenBrightness();
                  final _brightness = await ScreenBrightness.initial;
                  setState(() {
                    brightness = _brightness;
                  });
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
