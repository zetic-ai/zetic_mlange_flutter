import 'package:flutter_test/flutter_test.dart';
import 'package:zetic_mlange_flutter/zetic_mlange_model.dart';
import 'package:zetic_mlange_flutter/zetic_mlange_flutter_platform_interface.dart';
import 'package:zetic_mlange_flutter/zetic_mlange_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockZeticMlangeFlutterPlatform
    with MockPlatformInterfaceMixin
    implements ZeticMlangeFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ZeticMlangeFlutterPlatform initialPlatform = ZeticMlangeFlutterPlatform.instance;

  test('$MethodChannelZeticMlangeFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelZeticMlangeFlutter>());
  });

}
