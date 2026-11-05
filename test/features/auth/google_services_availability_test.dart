import 'package:echo_loop/features/auth/google_services_availability.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('top.echo-loop/google_services');

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Android 通过 MethodChannel 返回 Google Play services 可用状态', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'isGooglePlayServicesAvailable');
          return true;
        });

    final isAvailable = await const MethodChannelGoogleServicesAvailability()
        .isAvailable();

    expect(isAvailable, isTrue);
  });

  test('Android 检测异常时按不可用处理', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'unavailable');
        });

    final isAvailable = await const MethodChannelGoogleServicesAvailability()
        .isAvailable();

    expect(isAvailable, isFalse);
  });

  test('非 Android 平台不调用 MethodChannel 且返回不可用', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var called = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          called = true;
          return true;
        });

    final isAvailable = await const MethodChannelGoogleServicesAvailability()
        .isAvailable();

    expect(isAvailable, isFalse);
    expect(called, isFalse);
  });
}
