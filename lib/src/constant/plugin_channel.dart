import 'package:flutter/services.dart';

const pluginMethodChannelName = 'github.com/aaassseee/screen_brightness';

const pluginMethodChannel = MethodChannel(pluginMethodChannelName);

const pluginEventChannelCurrentBrigntnessChangeName =
    'github.com/aaassseee/screen_brightness/change';

const pluginEventChannelCurrentBrigntnessChange =
    EventChannel(pluginEventChannelCurrentBrigntnessChangeName);
