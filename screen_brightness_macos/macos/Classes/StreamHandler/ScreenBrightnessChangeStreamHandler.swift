//
//  ScreenBrightnessChangeEventHandler.swift
//  screen_brightness
//
//  Created by Jack on 8/12/2021.
//

import Cocoa
import FlutterMacOS

public class ScreenBrightnessChangeStreamHandler: BaseStreamHandler {
    public func addScreenBrightnessToEventSink(_ screenBrightness: Float) {
        guard let eventSink = eventSink else {
            return
        }
        
        eventSink(Double(screenBrightness))
    }
}
