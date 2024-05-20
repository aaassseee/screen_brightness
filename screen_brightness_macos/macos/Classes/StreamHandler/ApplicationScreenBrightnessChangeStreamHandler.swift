//
//  ScreenBrightnessChangeEventHandler.swift
//  screen_brightness
//
//  Created by Jack on 8/12/2021.
//

import Cocoa
import FlutterMacOS

public class ApplicationScreenBrightnessChangeStreamHandler: BaseStreamHandler {
    public func addApplicationScreenBrightnessToEventSink(_ applicationScreenBrightness: Float) {
        guard let eventSink = eventSink else {
            return
        }
        
        eventSink(Double(applicationScreenBrightness))
    }
}
