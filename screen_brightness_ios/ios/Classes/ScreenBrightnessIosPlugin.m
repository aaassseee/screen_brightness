#import "ScreenBrightnessIosPlugin.h"
#if __has_include(<screen_brightness_ios/screen_brightness_ios-Swift.h>)
#import <screen_brightness_ios/screen_brightness_ios-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "screen_brightness_ios-Swift.h"
#endif

@implementation ScreenBrightnessIosPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftScreenBrightnessIosPlugin registerWithRegistrar:registrar];
}
@end
