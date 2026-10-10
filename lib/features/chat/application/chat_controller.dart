import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum ChatRole { user, assistant }

class ChatModeInfo {
  final String label;
  const ChatModeInfo(this.label);
}

class ChatMessage {
  final String id;
  final String text;
  final ChatRole role;
  final ChatModeInfo mode;

  ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.mode,
  });
}

final chatControllerProvider = StateNotifierProvider<ChatController, List<ChatMessage>>((ref) {
  return ChatController();
});

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController() : super([]);

  Future<void> sendMessage(String messageText, bool isCloudMode, {String modeLabel = 'Standard'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_message', messageText);

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageText,
      role: ChatRole.user,
      mode: ChatModeInfo(isCloudMode ? 'CLOUD ($modeLabel)' : 'LOCAL ($modeLabel)'),
    );

    state = [...state, userMsg];

    if (isCloudMode) {
      try {
        final response = await http.post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': messageText}]
              }
            ]
          }),
        );

        String replyText;
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          replyText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Réponse Cloud vide';
        } else {
          replyText = 'Cloud Erreur: ${response.statusCode}';
        }

        final assistantMsg = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: replyText,
          role: ChatRole.assistant,
          mode: ChatModeInfo(modeLabel),
        );
        state = [...state, assistantMsg];
      } catch (e) {
        final errorMsg = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: 'Cloud Exception: $e',
          role: ChatRole.assistant,
          mode: ChatModeInfo('Erreur'),
        );
        state = [...state, errorMsg];
      }
    } else {
      final localReply = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: 'Réponse locale générée pour "$messageText"',
        role: ChatRole.assistant,
        mode: ChatModeInfo(modeLabel),
      );
      state = [...state, localReply];
    }
  }
}
