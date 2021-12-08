//
//  BaseEventHandler.swift
//  screen_brightness
//
//  Created by Jack on 8/12/2021.
//

import Cocoa
import FlutterMacOS

open class BaseStreamHandler: NSObject, FlutterStreamHandler {
    
    var eventSink: FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
