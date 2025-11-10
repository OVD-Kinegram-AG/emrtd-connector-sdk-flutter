import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emrtd/emrtd_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelEmrtd platform = MethodChannelEmrtd();
  const MethodChannel channel = MethodChannel('emrtd');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('read', () async {
    expect(await platform.read(), '42');
  });
}
