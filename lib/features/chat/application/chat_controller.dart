import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final chatControllerProvider = StateNotifierProvider<ChatController, List<String>>((ref) {
  return ChatController();
});

class ChatController extends StateNotifier<List<String>> {
  ChatController() : super([]);

  Future<void> sendMessage(String message, bool isCloudMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_message', message);

    state = [...state, 'Vous: $message'];

    if (isCloudMode) {
      try {
        final response = await http.post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': message}]
              }
            ]
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Réponse Cloud vide';
          state = [...state, 'Cloud: $text'];
        } else {
          state = [...state, 'Cloud Erreur: ${response.statusCode}'];
        }
      } catch (e) {
        state = [...state, 'Cloud Exception: $e'];
      }
    } else {
      state = [...state, 'Local: Réponse locale générée pour "$message"'];
    }
  }
}
