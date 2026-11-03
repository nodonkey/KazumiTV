import 'package:kazumi/bean/widget/tv_text_editing_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/bean/widget/tv_focusable_surface.dart';
import 'package:kazumi/bean/widget/phone_keyboard_control.dart';
import 'package:kazumi/bean/widget/phone_keyboard_target.dart';

/// Remote focus is an action, not an editable field. Text editing starts only
/// after explicit activation, in its own route so BACK restores this entry.
class TvSearchEntry extends StatefulWidget {
  const TvSearchEntry({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.suggestionsBuilder,
    this.onKeyEvent,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final WidgetBuilder? suggestionsBuilder;

  /// Lets the host claim navigation keys (for example DOWN into results)
  /// before the surface treats them as activation.
  final FocusOnKeyEventCallback? onKeyEvent;

  @override
  State<TvSearchEntry> createState() => _TvSearchEntryState();
}

class _TvSearchEntryState extends State<TvSearchEntry> {
  final _focus = FocusNode(debugLabel: 'TV search input entry');
  bool _opening = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opening) return;
    _opening = true;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SearchEditor(
        initialText: widget.controller.text,
        onPhoneConfirm: (text) {
          if (mounted) widget.controller.text = text;
        },
        suggestionsBuilder: widget.suggestionsBuilder,
      ),
    );
    _opening = false;
    if (!mounted) return;
    _focus.requestFocus();
    if (result != null) widget.onSubmitted(result);
  }

  @override
  Widget build(BuildContext context) => TvFocusableSurface(
        key: const Key('tv-search-entry'),
        focusNode: _focus,
        autofocus: true,
        borderRadius: 28,
        focusScale: 1,
        onPressed: _open,
        onKeyEvent: widget.onKeyEvent,
        child: SearchBar(
          controller: widget.controller,
          readOnly: true,
          hintText: '按 OK 输入名称或搜索条件',
          leading: const Icon(Icons.search),
          onTap: _open,
          elevation: const WidgetStatePropertyAll(0),
        ),
      );
}

class _SearchEditor extends StatefulWidget {
  const _SearchEditor(
      {required this.initialText,
      required this.onPhoneConfirm,
      this.suggestionsBuilder});
  final String initialText;
  final ValueChanged<String> onPhoneConfirm;
  final WidgetBuilder? suggestionsBuilder;

  @override
  State<_SearchEditor> createState() => _SearchEditorState();
}

class _SearchEditorState extends State<_SearchEditor> {
  late final editor = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PhoneKeyboardEditorTarget(
      controller: editor,
      label: '搜索关键词',
      maxLength: 120,
      inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
      onConfirm: () {
        widget.onPhoneConfirm(editor.text);
        Navigator.of(context).pop();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A single strip stays above the landscape keyboard; the old
                // titled dialog was taller than the remaining viewport.
                Row(children: [
                  Expanded(
                    child: TvTextEditingShortcuts(
                        child: TextField(
                      key: const Key('tv-search-editor'),
                      controller: editor,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) => Navigator.of(context).pop(value),
                      decoration: const InputDecoration(hintText: '输入名称或搜索条件'),
                    )),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: '取消',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const PhoneKeyboardButton(),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(editor.text),
                    child: const Text('检索'),
                  ),
                ]),
                if (widget.suggestionsBuilder != null)
                  Flexible(
                    child: SingleChildScrollView(
                      child: widget.suggestionsBuilder!(context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ));
}
