import 'package:flutter/services.dart';

const pluginMethodChannelName = 'github.com/aaassseee/screen_brightness';
const pluginMethodChannel = MethodChannel(pluginMethodChannelName);

const pluginEventChannelCurrentBrightnessChangeName =
    'github.com/aaassseee/screen_brightness/change';
const pluginEventChannelCurrentBrightnessChange =
    EventChannel(pluginEventChannelCurrentBrightnessChangeName);
