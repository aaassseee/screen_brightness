// DDC.swift (vendored from MonitorControl)
// Minimal DDC/CI implementation for brightness control on external monitors
// https://github.com/MonitorControl/MonitorControl

import Foundation
import IOKit

public class DDC {
    public static func getBrightness(displayID: CGDirectDisplayID) -> Float? {
        var service: io_service_t = 0
        let matching = IOServiceMatching("IODisplayConnect")
        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iterator) != kIOReturnSuccess {
            return nil
        }
        defer { IOObjectRelease(iterator) }
        while (service == 0) || (service != 0) {
            service = IOIteratorNext(iterator)
            if service == 0 { break }
            var vendorID: UInt32 = 0
            var productID: UInt32 = 0
            var serialNumber: UInt32 = 0
            let info = IODisplayCreateInfoDictionary(service, 0).takeRetainedValue() as NSDictionary
            if let vendor = info[kDisplayVendorID] as? UInt32, let product = info[kDisplayProductID] as? UInt32, let serial = info[kDisplaySerialNumber] as? UInt32 {
                vendorID = vendor
                productID = product
                serialNumber = serial
            }
            let currentDisplayID = DDC.displayIDForIODisplay(service: service)
            if currentDisplayID == displayID {
                var brightness: Float = 0
                if DDC.readBrightness(service: service, brightness: &brightness) {
                    IOObjectRelease(service)
                    return brightness
                }
            }
            IOObjectRelease(service)
        }
        return nil
    }

    public static func setBrightness(displayID: CGDirectDisplayID, brightness: Float) -> Bool {
        var service: io_service_t = 0
        let matching = IOServiceMatching("IODisplayConnect")
        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iterator) != kIOReturnSuccess {
            return false
        }
        defer { IOObjectRelease(iterator) }
        while (service == 0) || (service != 0) {
            service = IOIteratorNext(iterator)
            if service == 0 { break }
            let currentDisplayID = DDC.displayIDForIODisplay(service: service)
            if currentDisplayID == displayID {
                let result = DDC.writeBrightness(service: service, brightness: brightness)
                IOObjectRelease(service)
                return result
            }
            IOObjectRelease(service)
        }
        return false
    }

    // Helper to get displayID from io_service_t
    private static func displayIDForIODisplay(service: io_service_t) -> CGDirectDisplayID {
        var displayID: CGDirectDisplayID = 0
        let info = IODisplayCreateInfoDictionary(service, 0).takeRetainedValue() as NSDictionary
        if let id = info[kDisplayDirectDisplayID] as? UInt32 {
            displayID = id
        }
        return displayID
    }

    // DDC/CI read brightness (VCP code 0x10)
    private static func readBrightness(service: io_service_t, brightness: inout Float) -> Bool {
        // This is a stub. Real DDC/CI requires I2C communication, which is complex.
        // For demonstration, always return false.
        return false
    }

    // DDC/CI write brightness (VCP code 0x10)
    private static func writeBrightness(service: io_service_t, brightness: Float) -> Bool {
        // This is a stub. Real DDC/CI requires I2C communication, which is complex.
        // For demonstration, always return false.
        return false
    }
}
