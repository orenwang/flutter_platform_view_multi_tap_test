import Flutter
import UIKit

public class SwiftFlutterPlatformViewMultiTapTestPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_platform_view_multi_tap_test", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterPlatformViewMultiTapTestPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
      let factory = FLNativeViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "flutter-platform-view-multi-tap-test")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
