import 'package:flutter/material.dart';

import 'package:kazumi/bean/widget/tonal_card.dart';
import 'package:kazumi/services/platform/tv_mode.dart';

const double splitListOuterRadius = tonalCardRadius;
const double splitListInnerRadius = 4;
const double splitListRowGap = 4;

const Duration splitListMotionDuration = Duration(milliseconds: 250);
const Curve splitListMotionCurve = Curves.easeInOutCubic;

class SplitListRow extends StatefulWidget {
  const SplitListRow({
    super.key,
    required this.child,
    this.topRadius = splitListInnerRadius,
    this.bottomRadius = splitListInnerRadius,
    this.pressedRadius = splitListOuterRadius,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  final Widget child;

  final double topRadius;
  final double bottomRadius;
  final double pressedRadius;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Forward a child InkWell's onHighlightChanged here.
  static ValueChanged<bool>? pressReporterOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SplitRowScope>()
        ?.onPressChanged;
  }

  @override
  State<SplitListRow> createState() => _SplitListRowState();
}

class _SplitListRowState extends State<SplitListRow> {
  bool _pressed = false;
  bool _focused = false;
  FocusNode? _internalFocusNode;
  FocusNode? _listeningNode;

  FocusNode get _focusNode =>
      widget.focusNode ??
      (_internalFocusNode ??= FocusNode(debugLabel: 'Split list row'));

  @override
  void initState() {
    super.initState();
    _listenToFocusNode();
  }

  @override
  void didUpdateWidget(covariant SplitListRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode ||
        (oldWidget.onTap == null) != (widget.onTap == null)) {
      _listeningNode?.removeListener(_onFocusChange);
      _listeningNode = null;
      _listenToFocusNode();
    }
  }

  void _listenToFocusNode() {
    if (widget.onTap == null) return;
    final node = _focusNode;
    _listeningNode = node;
    _focused = node.hasFocus;
    node.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final focused = _listeningNode?.hasFocus ?? false;
    if (mounted && focused != _focused) {
      setState(() => _focused = focused);
    }
  }

  void _reportPress(bool pressed) => setState(() => _pressed = pressed);

  @override
  void dispose() {
    _listeningNode?.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final focusNode = widget.onTap == null ? null : _focusNode;
    final child = widget.onTap == null
        ? widget.child
        : InkWell(
            onTap: widget.onTap,
            focusNode: focusNode,
            autofocus: widget.autofocus,
            onHighlightChanged: _reportPress,
            child: widget.child,
          );
    final borderRadius = BorderRadius.vertical(
      top: Radius.circular(_pressed ? widget.pressedRadius : widget.topRadius),
      bottom: Radius.circular(
          _pressed ? widget.pressedRadius : widget.bottomRadius),
    );
    // Animate color as well as shape; Material alone snaps color changes.
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : splitListMotionDuration,
      curve: splitListMotionCurve,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: borderRadius,
      ),
      foregroundDecoration: TvMode.enabled && _focused
          ? BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: colors.primary, width: 3),
            )
          : null,
      child: Material(
        type: MaterialType.transparency,
        child: ListTileTheme(
          data: theme.listTileTheme.copyWith(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            titleTextStyle:
                theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
            subtitleTextStyle: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          child: _SplitRowScope(onPressChanged: _reportPress, child: child),
        ),
      ),
    );
  }
}

class _SplitRowScope extends InheritedWidget {
  const _SplitRowScope({required this.onPressChanged, required super.child});

  final ValueChanged<bool> onPressChanged;

  // The callback always targets the same state.
  @override
  bool updateShouldNotify(_SplitRowScope oldWidget) => false;
}

class SplitListGroup extends StatelessWidget {
  const SplitListGroup({
    super.key,
    required this.children,
    this.outerRadius = splitListOuterRadius,
  });

  final List<Widget> children;

  final double outerRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: splitListRowGap),
          SplitListRow(
            topRadius: i == 0 ? outerRadius : splitListInnerRadius,
            bottomRadius:
                i == children.length - 1 ? outerRadius : splitListInnerRadius,
            pressedRadius: outerRadius,
            child: children[i],
          ),
        ],
      ],
    );
  }
}
