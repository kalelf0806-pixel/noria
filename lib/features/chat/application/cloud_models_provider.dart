import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CloudModelInfo {
  final String id;
  final String displayName;
  final int inputTokenLimit;

  CloudModelInfo({
    required this.id,
    required this.displayName,
    required this.inputTokenLimit,
  });

  String get formattedTokens {
    if (inputTokenLimit >= 1048576) {
      return '${(inputTokenLimit / 1048576).toStringAsFixed(0)}M tokens';
    } else if (inputTokenLimit >= 1024) {
      return '${(inputTokenLimit / 1024).toStringAsFixed(0)}k tokens';
    }
    return '$inputTokenLimit tokens';
  }
}

final cloudModelsProvider = StateNotifierProvider<CloudModelsNotifier, List<CloudModelInfo>>((ref) {
  return CloudModelsNotifier();
});

class CloudModelsNotifier extends StateNotifier<List<CloudModelInfo>> {
  CloudModelsNotifier() : super([]) {
    fetchModels();
  }

  Future<void> fetchModels() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key') ?? '';

    if (apiKey.isEmpty) {
      state = []; // Liste vide si pas de clé API
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final modelsJson = data['models'] as List<dynamic>?;
        if (modelsJson != null) {
          final List<CloudModelInfo> loadedModels = [];
          for (final m in modelsJson) {
            final name = m['name'] as String?;
            final methods = m['supportedGenerationMethods'] as List<dynamic>?;
            if (name != null && methods != null && methods.contains('generateContent')) {
              final cleanId = name.replaceFirst('models/', '');
              final displayName = m['displayName'] as String? ?? cleanId;
              final tokenLimit = m['inputTokenLimit'] as int? ?? 1048576;
              loadedModels.add(CloudModelInfo(
                id: cleanId,
                displayName: displayName,
                inputTokenLimit: tokenLimit,
              ));
            }
          }
          state = loadedModels;
        }
      } else {
        state = [];
      }
    } catch (_) {
      state = [];
    }
  }
}
