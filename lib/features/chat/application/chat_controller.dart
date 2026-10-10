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

// Stocke le modèle sélectionné par l'utilisateur
final selectedCloudModelProvider = StateProvider<String?>((ref) => null);

final chatControllerProvider = StateNotifierProvider<ChatController, List<ChatMessage>>((ref) {
  return ChatController(ref);
});

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController(this._ref) : super([]);
  final Ref _ref;

  Future<void> sendMessage(String messageText, bool isCloudMode, {String modeLabel = 'Standard'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_message', messageText);
    final apiKey = prefs.getString('gemini_api_key') ?? '';
    final selectedCloudModel = _ref.read(selectedCloudModelProvider);

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageText,
      role: ChatRole.user,
      mode: ChatModeInfo(isCloudMode ? 'CLOUD (${selectedCloudModel ?? "Aucun"})' : 'LOCAL ($modeLabel)'),
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
          text: 'Erreur Cloud : Aucun modèle sélectionné. Veuillez d\'abord configurer votre clé API pour charger les modèles disponibles.',
          role: ChatRole.assistant,
          mode: ChatModeInfo('Erreur'),
        );
        state = [...state, errorMsg];
        return;
      }

      String? replyText;
      int statusCode = 500;
      String lastErrorBody = '';

      // Tentative avec mécanisme de réessai automatique (Retry) en cas de 503 (High demand)
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final response = await http.post(
            Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$selectedCloudModel:generateContent'),
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

          statusCode = response.statusCode;
          if (statusCode == 200) {
            final data = jsonDecode(response.body);
            replyText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Réponse Cloud vide';
            break;
          } else {
            lastErrorBody = response.body;
            if (statusCode == 503 && attempt == 1) {
              // Attente courte avant de retenter si le serveur est surchargé
              await Future.delayed(const Duration(milliseconds: 1500));
              continue;
            }
          }
        } catch (e) {
          lastErrorBody = e.toString();
        }
      }

      final finalReply = replyText ?? 'Cloud Erreur ($statusCode) sur [$selectedCloudModel] : $lastErrorBody';

      final assistantMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: finalReply,
        role: ChatRole.assistant,
        mode: ChatModeInfo(selectedCloudModel),
      );
      state = [...state, assistantMsg];
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
