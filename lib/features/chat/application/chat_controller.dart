import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inference/application/model_controller.dart';
import '../../inference/domain/inference_mode.dart';

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

  void send(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return;

    final mode = ref.read(inferenceModeProvider);
    final model = ref.read(modelControllerProvider);

    final reply = switch (mode) {
      InferenceMode.local when model is! ModelLoaded =>
        'Aucun modèle local chargé. Ouvrez le moniteur RAM pour charger un fichier GGUF.',
      InferenceMode.local => 'Runtime llama.cpp non branché (Phase 2).',
      InferenceMode.cloud => 'Fournisseur Gemini non branché (Phase 2).',
    };

    state = [
      ...state,
      ChatMessage(id: _nextId++, role: ChatRole.user, text: text, mode: mode),
      ChatMessage(id: _nextId++, role: ChatRole.system, text: reply, mode: mode),
    ];
  }

  void clear() => state = const [];
}
