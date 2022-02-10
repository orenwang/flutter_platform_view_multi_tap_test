#import "FlutterPlatformViewMultiTapTestPlugin.h"
#if __has_include(<flutter_platform_view_multi_tap_test/flutter_platform_view_multi_tap_test-Swift.h>)
#import <flutter_platform_view_multi_tap_test/flutter_platform_view_multi_tap_test-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_platform_view_multi_tap_test-Swift.h"
#endif

@implementation FlutterPlatformViewMultiTapTestPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterPlatformViewMultiTapTestPlugin registerWithRegistrar:registrar];
}
@end
