import 'package:flutter_test/flutter_test.dart';
import 'package:emrtd/emrtd.dart';
import 'package:emrtd/emrtd_platform_interface.dart';
import 'package:emrtd/emrtd_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEmrtdPlatform
    with MockPlatformInterfaceMixin
    implements EmrtdPlatform {
  @override
  Future<String?> read() => Future.value('42');
}

void main() {
  final EmrtdPlatform initialPlatform = EmrtdPlatform.instance;

  test('$MethodChannelEmrtd is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEmrtd>());
  });

  test('read', () async {
    Emrtd emrtdPlugin = Emrtd();
    MockEmrtdPlatform fakePlatform = MockEmrtdPlatform();
    EmrtdPlatform.instance = fakePlatform;

    expect(await emrtdPlugin.read(), '42');
  });
}
