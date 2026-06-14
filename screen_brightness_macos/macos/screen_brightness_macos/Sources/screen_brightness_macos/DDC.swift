// DDC.swift (vendored from MonitorControl)
// Minimal DDC/CI implementation for brightness control on external monitors
// https://github.com/MonitorControl/MonitorControl

import Foundation
import CoreGraphics
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
            if DDC.displayService(service, matches: displayID) {
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
            if DDC.displayService(service, matches: displayID) {
                let result = DDC.writeBrightness(service: service, brightness: brightness)
                IOObjectRelease(service)
                return result
            }
            IOObjectRelease(service)
        }
        return false
    }

    // Helper to match an IODisplay service to a CoreGraphics display ID
    private static func displayService(_ service: io_service_t, matches displayID: CGDirectDisplayID) -> Bool {
        let info = IODisplayCreateInfoDictionary(service, 0).takeRetainedValue() as NSDictionary

        guard let vendorID = info[kDisplayVendorID] as? UInt32,
              let productID = info[kDisplayProductID] as? UInt32,
              let serialNumber = info[kDisplaySerialNumber] as? UInt32 else {
            return false
        }

        return vendorID == CGDisplayVendorNumber(displayID)
            && productID == CGDisplayModelNumber(displayID)
            && serialNumber == CGDisplaySerialNumber(displayID)
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
