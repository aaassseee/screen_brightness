import 'package:flutter/services.dart';

const pluginMethodChannelName = 'github.com/aaassseee/screen_brightness';
const pluginMethodChannel = MethodChannel(pluginMethodChannelName);

const pluginEventChannelApplicationBrightnessChangedName =
    'github.com/aaassseee/screen_brightness/application_brightness_changed';
const pluginEventChannelApplicationBrightnessChanged =
    EventChannel(pluginEventChannelApplicationBrightnessChangedName);

const pluginEventChannelSystemBrightnessChangedName =
    'github.com/aaassseee/screen_brightness/system_brightness_changed';
const pluginEventChannelSystemBrightnessChanged =
    EventChannel(pluginEventChannelSystemBrightnessChangedName);
