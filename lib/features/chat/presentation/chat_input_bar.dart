import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/chat_controller.dart';
import '../application/cloud_models_provider.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final cloudModels = ref.watch(cloudModelsProvider);
    final currentCloudModel = ref.watch(selectedCloudModelProvider);

    // Sélection automatique du premier modèle si aucun n'est sélectionné et que la liste est dispo
    if (cloudModels.isNotEmpty && (currentCloudModel == null || !cloudModels.any((m) => m.id == currentCloudModel))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCloudModelProvider.notifier).state = cloudModels.first.id;
      });
    }

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
                  if (cloudModels.isEmpty)
                    const Text(
                      'Clé API requise (dans le menu ⚙️)',
                      style: TextStyle(fontFamily: NoriaTheme.mono, fontSize: 11, color: Colors.orangeAccent),
                    )
                  else
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: cloudModels.any((m) => m.id == currentCloudModel) ? currentCloudModel : cloudModels.first.id,
                        dropdownColor: Colors.black,
                        style: const TextStyle(fontFamily: NoriaTheme.mono, fontSize: 12, color: Colors.white),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: cloudModels.map((model) {
                          return DropdownMenuItem<String>(
                            value: model.id,
                            child: Text(
                              '${model.id} (${model.formattedTokens})',
                              style: const TextStyle(color: Colors.white),
                            ),
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
                    hintText: isCloudMode ? 'Envoyer à [${currentCloudModel ?? "Sélectionner un modèle"}]...' : 'Envoyer au modèle local (FFI)...',
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
