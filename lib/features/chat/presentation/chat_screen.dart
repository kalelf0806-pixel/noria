import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../resources/presentation/resource_badge.dart';
import 'chat_input_bar.dart';
import 'message_list.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: const SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: MessageList()),
            ChatInputBar(),
          ],
        ),
      ),
    );
  }
}
