import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_platform_view_multi_tap_test/flutter_platform_view_multi_tap_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_platform_view_multi_tap_test');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterPlatformViewMultiTapTest.platformVersion, '42');
  });
}
