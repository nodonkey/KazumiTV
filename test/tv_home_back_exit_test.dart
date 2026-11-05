import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/services/platform/tv_mode.dart';
import 'package:kazumi/services/platform/tv_navigation.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'support/tv_focus_fixtures.dart';

class _TempPaths extends PathProviderPlatform {
  _TempPaths(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late List<MethodCall> platformCalls;

  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('kazumi_home_back_');
    PathProviderPlatform.instance = _TempPaths(temp.path);
    Hive.init(temp.path);
    await GStorage.init();
  });
  tearDownAll(() async {
    await Hive.close();
    await temp.delete(recursive: true);
  });
  setUp(() {
    TvMode.setEnabledForTesting(true);
    platformCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    TvMode.setEnabledForTesting(false);
  });

  testWidgets('TV home BACK prompts once, then exits on the second press',
      (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(FocusFixtureApp());
    await tester.pumpAndSettle();

    final homeRequests = TvNavigation.homeRequests.value;
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('再按一次退出应用'), findsOneWidget);
    expect(TvNavigation.homeRequests.value, homeRequests,
        reason: 'BACK at the home root must not consume the key');
    expect(
        platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
        isEmpty);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(platformCalls.map((call) => call.method),
        contains('SystemNavigator.pop'));
    expect(tester.takeException(), isNull);
  });
}
