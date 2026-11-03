import 'package:flutter/material.dart';
import 'package:kazumi/modules/roads/road_module.dart';
import 'package:kazumi/services/player/cross_source_resume.dart';

/// Same-work/season transfer picker. The option list scrolls inside the body
/// while the "手动选集" action stays pinned, so short TV viewports neither
/// overflow nor hide the action row.
class CrossSourceResumeDialog extends StatelessWidget {
  const CrossSourceResumeDialog({
    super.key,
    required this.choices,
    required this.roads,
  });

  final List<CrossSourceResume> choices;
  final List<Road> roads;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text('同集换源', style: theme.textTheme.headlineSmall),
              ),
              const SizedBox(height: 8),
              Text(
                '确认新结果是同一作品和季度后，可继续同集；无法确认时请手动选集，从头播放。',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: choices.length,
                  itemBuilder: (context, i) {
                    final choice = choices[i];
                    final road = roads[choice.road];
                    return TextButton(
                      autofocus: i == 0,
                      onPressed: () => Navigator.pop(context, i),
                      child: Text('${road.name} · '
                          '${road.identifier[choice.episode - 1]} · '
                          '继续 ${choice.offset} 秒'),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, -1),
                  child: const Text('手动选集'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
