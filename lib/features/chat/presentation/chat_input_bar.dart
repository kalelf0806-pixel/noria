import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/chat_controller.dart';

class ChatInputBar extends ConsumerWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isCloudMode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isCloudMode;
  final VoidCallback onSubmitted;

  // Liste complète des modèles Cloud disponibles d'après les endpoints officiels de Google
  static const List<String> availableCloudModels = [
    'gemini-3.8-flash',
    'gemini-3.5-flash',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-3.1-pro-preview',
    'gemini-3-flash-preview',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final currentCloudModel = ref.watch(selectedCloudModelProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline, width: NoriaTheme.borderWidth)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCloudMode) ...[
            // Sélecteur sous forme de liste déroulante (DropdownButton) dépliable
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                border: Border.all(color: colors.outline, width: NoriaTheme.borderWidth),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MODÈLE CLOUD :',
                    style: TextStyle(fontFamily: NoriaTheme.mono, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: availableCloudModels.contains(currentCloudModel) ? currentCloudModel : availableCloudModels.first,
                      dropdownColor: Colors.black,
                      style: const TextStyle(fontFamily: NoriaTheme.mono, fontSize: 12, color: Colors.white),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: availableCloudModels.map((model) {
                        return DropdownMenuItem<String>(
                          value: model,
                          child: Text(model, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(selectedCloudModelProvider.notifier).state = val;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontFamily: NoriaTheme.mono, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isCloudMode ? 'Envoyer à [$currentCloudModel]...' : 'Envoyer au modèle local (FFI)...',
                    hintStyle: TextStyle(color: colors.onSurfaceVariant.withOpacity(0.5)),
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: colors.outline, width: NoriaTheme.borderWidth),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: colors.outline, width: NoriaTheme.borderWidth),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: colors.onSurface, width: NoriaTheme.borderWidth),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => onSubmitted(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onSubmitted,
                style: IconButton.styleFrom(
                  backgroundColor: colors.onSurface,
                  foregroundColor: colors.surface,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
