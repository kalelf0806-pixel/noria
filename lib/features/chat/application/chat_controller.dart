import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../inference/application/model_controller.dart';
import '../../inference/domain/local_inference_engine.dart';

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
  return ChatController(ref);
});

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController(this._ref) : super([]);
  final Ref _ref;

  /// Découvre dynamiquement le premier modèle Cloud supportant generateContent
  Future<String?> _discoverActiveModel(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List<dynamic>?;
        if (models != null) {
          for (final m in models) {
            final name = m['name'] as String?; // ex: "models/gemini-1.5-flash" ou "models/gemini-2.5-flash"
            final methods = m['supportedGenerationMethods'] as List<dynamic>?;
            if (name != null && methods != null && methods.contains('generateContent')) {
              // On retire le préfixe "models/" si présent pour l'URL d'appel
              return name.replaceFirst('models/', '');
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> sendMessage(String messageText, bool isCloudMode, {String modeLabel = 'Standard'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_message', messageText);
    final apiKey = prefs.getString('gemini_api_key') ?? '';

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageText,
      role: ChatRole.user,
      mode: ChatModeInfo(isCloudMode ? 'CLOUD ($modeLabel)' : 'LOCAL ($modeLabel)'),
    );

    state = [...state, userMsg];

    if (isCloudMode) {
      if (apiKey.isEmpty) {
        final errorMsg = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: 'Erreur Cloud : Clé API Gemini manquante. Configurez-la dans le panneau de ressources (badge en haut à droite).',
          role: ChatRole.assistant,
          mode: ChatModeInfo('Erreur'),
        );
        state = [...state, errorMsg];
        return;
      }

      // 1. Découverte dynamique du modèle valide
      final activeModel = await _discoverActiveModel(apiKey) ?? 'gemini-1.5-flash';

      try {
        final response = await http.post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$activeModel:generateContent'),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
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
          replyText = 'Cloud Erreur (${response.statusCode}) sur [$activeModel] : ${response.body}';
        }

        final assistantMsg = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: replyText,
          role: ChatRole.assistant,
          mode: ChatModeInfo('$modeLabel ($activeModel)'),
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
      // Appel du moteur local FFI / Stub
      final engine = _ref.read(localEngineProvider);
      final reply = engine.infer(messageText);

      final localReply = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: reply,
        role: ChatRole.assistant,
        mode: ChatModeInfo(modeLabel),
      );
      state = [...state, localReply];
    }
  }
}
