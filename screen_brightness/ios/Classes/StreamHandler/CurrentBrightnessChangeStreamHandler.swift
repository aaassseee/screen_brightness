//
//  ScreenBrightnessChangeEventHandler.swift
//  screen_brightness
//
//  Created by Jack on 25/10/2021.
//

import Foundation
import Flutter
import UIKit

public class CurrentBrightnessChangeStreamHandler: BaseStreamHandler {
    public func addCurrentBrightnessToEventSink(_ currentBrightness: CGFloat) {
        guard let eventSink = eventSink else {
            return
        }
        
        eventSink(Double(currentBrightness))
    }
}
