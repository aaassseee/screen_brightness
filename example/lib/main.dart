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
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    double _brightness;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      _brightness = await ScreenBrightness.current;
    } on PlatformException {
      throw 'Failed to get screen brightness';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
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
                  ScreenBrightness.resetScreenBrightness();
                  final _brightness = await ScreenBrightness.current;
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
