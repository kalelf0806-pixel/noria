import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/chat_controller.dart';
import 'mode_switch.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({super.key});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(chatControllerProvider.notifier).send(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outline, width: NoriaTheme.borderWidth)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModeSwitch(),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(hintText: 'Message…'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox.square(
                  dimension: 44,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Icon(Icons.arrow_upward, semanticLabel: 'Envoyer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
