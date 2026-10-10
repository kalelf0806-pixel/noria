import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

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
  final String? imagePath;

  ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.mode,
    this.imagePath,
  });
}

final selectedCloudModelProvider = StateProvider<String?>((ref) => null);

final chatControllerProvider = StateNotifierProvider<ChatController, List<ChatMessage>>((ref) {
  return ChatController(ref);
});

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController(this._ref) : super([]);
  final Ref _ref;

  Future<void> sendMessage(String messageText, bool isCloudMode, {String? imagePath, String modeLabel = 'Standard'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_message', messageText);
    final apiKey = prefs.getString('gemini_api_key') ?? '';
    final selectedCloudModel = _ref.read(selectedCloudModelProvider);

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageText,
      role: ChatRole.user,
      mode: ChatModeInfo(isCloudMode ? 'CLOUD (${selectedCloudModel ?? "Standard"})' : 'LOCAL ($modeLabel)'),
      imagePath: imagePath,
    );

    state = [...state, userMsg];

    if (isCloudMode) {
      if (apiKey.isEmpty) {
        final errorMsg = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: 'Erreur Cloud : Clé API Gemini manquante. Configurez-la dans le panneau ressources (badge en haut à droite).',
          role: ChatRole.assistant,
          mode: ChatModeInfo('Erreur'),
        );
        state = [...state, errorMsg];
        return;
      }

      if (selectedCloudModel == null) {
        final errorMsg = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: 'Erreur Cloud : Aucun modèle sélectionné.',
          role: ChatRole.assistant,
          mode: ChatModeInfo('Erreur'),
        );
        state = [...state, errorMsg];
        return;
      }

      try {
        // Construction de la charge utile (Payload) multimodale pour l'API Gemini
        final List<dynamic> parts = [{'text': messageText.isEmpty ? 'Décris cette image.' : messageText}];

        if (imagePath != null && File(imagePath).existsSync()) {
          final bytes = await File(imagePath).readAsBytes();
          final base64Image = base64Encode(bytes);
          parts.add({
            'inline_data': {
              'mime_type': 'image/jpeg',
              'data': base64Image,
            }
          });
        }

        final response = await http.post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$selectedCloudModel:generateContent'),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': parts,
              }
            ]
          }),
        );

        String replyText;
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          replyText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Réponse Cloud vide';
        } else {
          replyText = 'Cloud Erreur (${response.statusCode}) : ${response.body}';
        }

        final assistantMsg = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: replyText,
          role: ChatRole.assistant,
          mode: ChatModeInfo(selectedCloudModel),
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
      // Appel du moteur local FFI natif
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
