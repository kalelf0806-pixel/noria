import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/chat_controller.dart';

class MessageList extends ConsumerWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatControllerProvider);
    final colors = Theme.of(context).colorScheme;

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'AUCUN MESSAGE\nChoisissez LOCAL ou CLOUD, puis écrivez.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: NoriaTheme.mono,
              color: colors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MessageBubble(message: message, key: ValueKey(message.id)),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser ? colors.primary : colors.surface,
            border: Border.all(color: colors.outline, width: NoriaTheme.borderWidth),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isUser ? 'VOUS · ${message.mode.label}' : 'NORIA · ${message.mode.label}',
                  style: TextStyle(
                    fontFamily: NoriaTheme.mono,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: (isUser ? colors.onPrimary : colors.onSurface).withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.text,
                  style: TextStyle(
                    color: isUser ? colors.onPrimary : colors.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
