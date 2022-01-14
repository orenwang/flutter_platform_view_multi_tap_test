
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterPlatformViewMultiTapTest {
  static const MethodChannel _channel = MethodChannel('flutter_platform_view_multi_tap_test');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
