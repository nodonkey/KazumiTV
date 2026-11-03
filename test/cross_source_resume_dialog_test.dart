import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/roads/road_module.dart';
import 'package:kazumi/pages/info/cross_source_resume_dialog.dart';
import 'package:kazumi/services/player/cross_source_resume.dart';

List<Road> _roads(int count) => List.generate(
      count,
      (i) => Road(
        name: '线路 ${i + 1} 备用播放地址',
        data: List.generate(12, (e) => 'https://example.com/$i/$e'),
        identifier: List.generate(12, (e) => '第${e + 1}集'),
      ),
    );

List<CrossSourceResume> _choices(int count, int roadCount) =>
    List.generate(
      count,
      (i) => CrossSourceResume(
        bangumiId: 1,
        pluginName: 'test',
        src: 'https://example.com/$i',
        road: i % roadCount,
        episode: (i % 12) + 1,
        episodePageUrl: 'https://example.com/${i % roadCount}/${i % 12}',
        offset: 30 * (i + 1),
      ),
    );

String _label(List<Road> roads, CrossSourceResume choice) =>
    '${roads[choice.road].name} · '
    '${roads[choice.road].identifier[choice.episode - 1]} · '
    '继续 ${choice.offset} 秒';

Future<void> _openDialog(
  WidgetTester tester, {
  required Size size,
  required List<Road> roads,
  required List<CrossSourceResume> choices,
  void Function(int?)? onResult,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await showDialog<int>(
                context: context,
                builder: (_) => CrossSourceResumeDialog(
                  choices: choices,
                  roads: roads,
                ),
              );
              onResult?.call(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('short TV viewport keeps the action row visible without overflow',
      (tester) async {
    final roads = _roads(2);
    final choices = _choices(12, roads.length);
    await _openDialog(
      tester,
      size: const Size(914, 411),
      roads: roads,
      choices: choices,
    );

    expect(tester.takeException(), isNull);
    final action = tester.getRect(find.text('手动选集'));
    expect(action.bottom, lessThanOrEqualTo(411));
    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets('the last option is reachable by scrolling and selectable',
      (tester) async {
    final roads = _roads(3);
    final choices = _choices(12, roads.length);
    int? result;
    await _openDialog(
      tester,
      size: const Size(914, 411),
      roads: roads,
      choices: choices,
      onResult: (value) => result = value,
    );

    final lastLabel = _label(roads, choices.last);
    await tester.scrollUntilVisible(
      find.text(lastLabel),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text(lastLabel));
    await tester.pumpAndSettle();

    expect(result, choices.length - 1);
  });

  testWidgets('first option takes focus and the manual-selection action exits',
      (tester) async {
    final roads = _roads(1);
    final choices = _choices(3, roads.length);
    int? result;
    await _openDialog(
      tester,
      size: const Size(914, 411),
      roads: roads,
      choices: choices,
      onResult: (value) => result = value,
    );

    final focusedButton = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<TextButton>();
    expect(focusedButton, isNotNull);
    expect(
      find.ancestor(
        of: find.text(_label(roads, choices.first)),
        matching: find.byType(TextButton),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('手动选集'));
    await tester.pumpAndSettle();
    expect(result, -1);
  });

  testWidgets('very short viewport still scrolls instead of overflowing',
      (tester) async {
    final roads = _roads(2);
    final choices = _choices(8, roads.length);
    await _openDialog(
      tester,
      size: const Size(800, 320),
      roads: roads,
      choices: choices,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('手动选集'), findsOneWidget);
  });
}
