#import "ScreenBrightnessPlugin.h"
#if __has_include(<screen_brightness/screen_brightness-Swift.h>)
#import <screen_brightness/screen_brightness-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "screen_brightness-Swift.h"
#endif

@implementation ScreenBrightnessPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftScreenBrightnessPlugin registerWithRegistrar:registrar];
}
@end
