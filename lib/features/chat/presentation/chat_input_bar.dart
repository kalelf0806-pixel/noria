import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/theme/app_theme.dart';
import '../application/chat_controller.dart';
import '../application/cloud_models_provider.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isCloudMode,
    required this.onSubmitted,
    this.onImageSelected,
  });

  final TextEditingController controller;
  final bool isCloudMode;
  final VoidCallback onSubmitted;
  final ValueChanged<String?>? onImageSelected;

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cloudModels = ref.watch(cloudModelsProvider);
    final currentCloudModel = ref.watch(selectedCloudModelProvider);

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
          if (widget.isCloudMode) ...[
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
                      'Clé API requise (menu ⚙️)',
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
          if (_selectedImagePath != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: colors.outline),
              ),
              child: Row(
                children: [
                  Image.file(File(_selectedImagePath!), width: 40, height: 40, fit: BoxFit.cover),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Image jointe prête', style: TextStyle(fontFamily: NoriaTheme.mono, fontSize: 11)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _selectedImagePath = null),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              if (widget.isCloudMode) ...[
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  tooltip: 'Joindre une image',
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: 'Prendre une photo',
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: const TextStyle(fontFamily: NoriaTheme.mono, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: widget.isCloudMode ? 'Envoyer au Cloud (multimodal)...' : 'Envoyer au modèle local (FFI)...',
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
                  onSubmitted: (_) {
                    widget.onSubmitted();
                    setState(() => _selectedImagePath = null);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  // Passer l'image au controller si besoin
                  if (_selectedImagePath != null) {
                    ref.read(chatControllerProvider.notifier).sendMessage(
                      widget.controller.text.trim(),
                      widget.isCloudMode,
                      imagePath: _selectedImagePath,
                    );
                    widget.controller.clear();
                    setState(() => _selectedImagePath = null);
                  } else {
                    widget.onSubmitted();
                  }
                },
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
