import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/resource_providers.dart';
import '../../inference/domain/inference_mode.dart';
import '../../inference/application/model_controller.dart';
import '../../inference/domain/local_inference_engine.dart';
import '../domain/ram_guard.dart';
import '../../../core/utils/bytes.dart';

class ResourcePanel extends StatefulWidget {
  const ResourcePanel({super.key});

  @override
  State<ResourcePanel> createState() => _ResourcePanelState();
}

class _ResourcePanelState extends State<ResourcePanel> {
  late final TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      _apiKeyController.text = prefs.getString('gemini_api_key') ?? '';
    }
  }

  Future<void> _saveApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', value.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clé API Gemini enregistrée avec succès !')),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final memoryAsync = ref.watch(memorySnapshotProvider);
        final engine = ref.watch(localEngineProvider);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'TÉLÉMÉTRIE MATÉRIELLE',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            memoryAsync.when(
              data: (snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: snapshot.usedRatio,
                    backgroundColor: Colors.grey.shade900,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Process : ${formatBytes(snapshot.appBytes)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      Text('RAM Système : ${formatPercent(snapshot.usedRatio)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Puce : Qualcomm SM8350 (Snapdragon 888)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(engine.isLoaded ? '⚡ Actif (NPU)' : '💤 IDLE', style: TextStyle(color: engine.isLoaded ? Colors.greenAccent : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur de lecture RAM', style: TextStyle(color: Colors.red)),
            ),
            const Divider(height: 32),
            const Text(
              'CONFIGURATION CLOUD (GEMINI API)',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Entrer la clé API Gemini...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade900,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save, color: Colors.white, size: 20),
                  onPressed: () => _saveApiKey(_apiKeyController.text),
                ),
              ),
              onSubmitted: _saveApiKey,
            ),
            const Divider(height: 32),
            const Text(
              'MOTEUR LOCAL (GGUF / LITERTLM)',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(engine.isLoaded ? 'Statut : Chargé en RAM' : 'Statut : Aucun modèle', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: engine.isLoaded ? Colors.red.shade900 : Colors.white,
                    foregroundColor: engine.isLoaded ? Colors.white : Colors.black,
                  ),
                  onPressed: () => engine.isLoaded ? _ejectModel(ref) : _pickAndLoad(context, ref),
                  icon: Icon(engine.isLoaded ? Icons.eject : Icons.folder_open, size: 16),
                  label: Text(engine.isLoaded ? 'EJECT' : 'CHARGER MODÈLE'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndLoad(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = picked?.files.single.path;
    if (path == null || !context.mounted) return;

    if (!path.toLowerCase().endsWith('.gguf') && !path.toLowerCase().endsWith('.litertlm')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un fichier .gguf ou .litertlm valide')),
      );
      return;
    }

    final controller = ref.read(modelControllerProvider.notifier);
    await controller.load(path, backend: ComputeBackend.npu);
  }

  Future<void> _ejectModel(WidgetRef ref) async {
    final controller = ref.read(modelControllerProvider.notifier);
    await controller.eject();
  }
}
