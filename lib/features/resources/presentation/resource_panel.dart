import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../application/resource_providers.dart';
import '../../inference/domain/inference_mode.dart';
import '../../inference/application/model_controller.dart';
import '../../inference/domain/local_inference_engine.dart';
import '../domain/ram_guard.dart';
import '../../core/utils/bytes.dart';

class ResourcePanel extends ConsumerWidget {
  const ResourcePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryAsync = ref.watch(memorySnapshotProvider);
    final engine = ref.watch(localEngineProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'RESSOURCES & TÉLÉMÉTRIE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Process : ${formatBytes(snapshot.processRss)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('RAM Système : ${formatPercent(snapshot.usedRatio)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Puce : Qualcomm SM8350 (Snapdragon 888)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(engine.isLoaded ? '⚡ Actif (NPU)' : '💤 IDLE', style: TextStyle(color: engine.isLoaded ? Colors.greenAccent : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Erreur de lecture RAM', style: TextStyle(color: Colors.red)),
          ),
          const Divider(color: Colors.grey, height: 24),
          const Text(
            'MODÈLE LOCAL (GGUF / LITERTLM)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
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
      ),
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
