//
//  ScreenBrightnessChangeEventHandler.swift
//  screen_brightness
//
//  Created by Jack on 25/10/2021.
//

import Foundation
import Flutter
import UIKit

public class ApplicationScreenBrightnessChangeStreamHandler: BaseStreamHandler {
    public func addApplicationScreenBrightnessToEventSink(_ applicationScreenBrightness: CGFloat) {
        guard let eventSink = eventSink else {
            return
        }
        
        eventSink(Double(applicationScreenBrightness))
    }
}
