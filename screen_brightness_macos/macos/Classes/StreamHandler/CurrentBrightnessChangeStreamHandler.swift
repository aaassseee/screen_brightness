//
//  ScreenBrightnessChangeEventHandler.swift
//  screen_brightness
//
//  Created by Jack on 8/12/2021.
//

import Cocoa
import FlutterMacOS

public class CurrentBrightnessChangeStreamHandler: BaseStreamHandler {
    public func addCurrentBrightnessToEventSink(_ currentBrightness: Float) {
        guard let eventSink = eventSink else {
            return
        }
        
        eventSink(Double(currentBrightness))
    }
}
