import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../resources/presentation/resource_badge.dart';
import '../application/chat_controller.dart';
import '../../inference/application/model_controller.dart';
import '../../inference/domain/inference_mode.dart';
import 'chat_input_bar.dart';
import 'message_list.dart';
import 'mode_switch.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inferenceMode = ref.watch(inferenceModeProvider);
    final isCloudMode = inferenceMode == InferenceMode.cloud;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NORIA',
          style: TextStyle(
            fontFamily: NoriaTheme.mono,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
            fontSize: 18,
          ),
        ),
        actions: const [ResourceBadge(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ModeSwitch(),
            ),
            const Expanded(child: MessageList()),
            ChatInputBar(
              controller: _textController,
              isCloudMode: isCloudMode,
              onSubmitted: () {
                final text = _textController.text.trim();
                if (text.isEmpty) return;
                _textController.clear();
                ref.read(chatControllerProvider.notifier).sendMessage(text, isCloudMode);
              },
            ),
          ],
        ),
      ),
    );
  }
}
