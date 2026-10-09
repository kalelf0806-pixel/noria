import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../inference/application/model_controller.dart';
import '../../inference/domain/inference_mode.dart';
import '../../inference/infrastructure/ffi_local_engine.dart';

enum ChatRole { user, assistant, system }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.mode,
  });

  final int id;
  final ChatRole role;
  final String text;
  final InferenceMode mode;
}

final chatControllerProvider =
    NotifierProvider<ChatController, List<ChatMessage>>(ChatController.new);

class ChatController extends Notifier<List<ChatMessage>> {
  int _nextId = 0;

  @override
  List<ChatMessage> build() => const [];

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    final mode = ref.read(inferenceModeProvider);
    final model = ref.read(modelControllerProvider);

    // Ajout du message de l'utilisateur
    state = [
      ...state,
      ChatMessage(id: _nextId++, role: ChatRole.user, text: text, mode: mode),
    ];

    // Mode Local : exécution native C++ FFI
    if (mode == InferenceMode.local) {
      if (model is! ModelLoaded) {
        state = [
          ...state,
          ChatMessage(
            id: _nextId++,
            role: ChatRole.system,
            text: 'Aucun modèle local chargé. Ouvrez le moniteur RAM pour charger un fichier GGUF.',
            mode: mode,
          ),
        ];
        return;
      }

      final engine = ref.read(localEngineProvider);
      final reply = (engine is FfiLocalEngine)
          ? engine.infer(text)
          : '[Local] Modèle ${model.name} chargé (${model.backend.label}).';

      state = [
        ...state,
        ChatMessage(id: _nextId++, role: ChatRole.assistant, text: reply, mode: mode),
      ];
      return;
    }

    // Mode Cloud Gemini REST
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key') ?? '';
    final selectedModel = prefs.getString('gemini_model') ?? 'gemini-3.8-flash';

    if (apiKey.isEmpty) {
      state = [
        ...state,
        ChatMessage(
          id: _nextId++,
          role: ChatRole.system,
          text: 'Clé API Gemini manquante. Renseignez-la dans le moniteur de ressources.',
          mode: mode,
        ),
      ];
      return;
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$selectedModel:generateContent?key=$apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': text}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final replyText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            'Réponse vide reçue de Gemini.';

        state = [
          ...state,
          ChatMessage(id: _nextId++, role: ChatRole.assistant, text: replyText, mode: mode),
        ];
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['message'] ?? response.body;
        state = [
          ...state,
          ChatMessage(
            id: _nextId++,
            role: ChatRole.system,
            text: 'Erreur Gemini (${response.statusCode}) : $errorMsg',
            mode: mode,
          ),
        ];
      }
    } catch (e) {
      state = [
        ...state,
        ChatMessage(
          id: _nextId++,
          role: ChatRole.system,
          text: 'Erreur de connexion : $e',
          mode: mode,
        ),
      ];
    }
  }

  void clear() => state = const [];
}
