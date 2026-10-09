import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bytes.dart';
import '../../inference/application/model_controller.dart';
import '../application/resource_providers.dart';
import '../domain/memory_snapshot.dart';
import '../domain/ram_guard.dart';
import 'resource_badge.dart';

class ResourcePanel extends ConsumerWidget {
  const ResourcePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(memorySnapshotProvider);
    final model = ref.watch(modelControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('RESSOURCES'),
            const SizedBox(height: 12),
            switch (snapshot) {
              AsyncData(:final value) => _MemoryDetails(snapshot: value),
              AsyncError(:final error) => Text('Sonde native indisponible : $error'),
              _ => const LinearProgressIndicator(),
            },
            const SizedBox(height: 24),
            const _SectionTitle('MODÈLE LOCAL'),
            const SizedBox(height: 12),
            _ModelStatus(state: model),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: model is ModelLoading ? null : () => _pickAndLoad(context, ref),
                    child: const Text('CHARGER GGUF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: model is ModelLoaded
                        ? () => ref.read(modelControllerProvider.notifier).eject()
                        : null,
                    style: FilledButton.styleFrom(backgroundColor: NoriaColors.danger),
                    child: const Text('EJECT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndLoad(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = picked?.files.single.path;
    if (path == null || !context.mounted) return;

    if (!path.toLowerCase().endsWith('.gguf')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un fichier .gguf')),
      );
      return;
    }

    final controller = ref.read(modelControllerProvider.notifier);
    final guard = await controller.evaluate(path);
    if (!context.mounted) return;

    final proceed = switch (guard.verdict) {
      GuardVerdict.allow => true,
      GuardVerdict.warn => await _confirm(context, guard),
      GuardVerdict.block => await _showBlocked(context, guard),
    };

    if (proceed) await controller.load(path);
  }

  Future<bool> _confirm(BuildContext context, RamGuardResult guard) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avertissement RAM'),
        content: Text(
          '${guard.reason}\n\nEstimation : ${formatBytes(guard.estimatedBytes)} '
          '(${formatPercent(guard.ratioOfTotal)} de la RAM totale).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('CHARGER')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<bool> _showBlocked(BuildContext context, RamGuardResult guard) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chargement bloqué'),
        content: Text(
          '${guard.reason}\n\nEstimation : ${formatBytes(guard.estimatedBytes)} '
          '(${formatPercent(guard.ratioOfTotal)} de la RAM totale).',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
    return false;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: NoriaTheme.mono,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
      ),
    );
  }
}

class _MemoryDetails extends StatelessWidget {
  const _MemoryDetails({required this.snapshot});
  final MemorySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: snapshot.usedRatio.clamp(0, 1),
          minHeight: 10,
          color: pressureColor(snapshot, colors.primary),
        ),
        const SizedBox(height: 12),
        _Row('Noria (process)', formatBytes(snapshot.appBytes)),
        _Row('Système utilisé', '${formatBytes(snapshot.usedBytes)} · ${formatPercent(snapshot.usedRatio)}'),
        _Row('Disponible', formatBytes(snapshot.availableBytes)),
        _Row('Total', formatBytes(snapshot.totalBytes)),
        _Row('Puce', snapshot.chip ?? '—'),
        if (snapshot.lowMemory)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Mémoire basse signalée par le système.',
              style: TextStyle(color: NoriaColors.danger, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _ModelStatus extends StatelessWidget {
  const _ModelStatus({required this.state});
  final ModelState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ModelIdle() => const _Row('État', 'Aucun modèle en RAM'),
      ModelLoading(:final name) => _Row('Chargement', name),
      ModelLoaded(:final name, :final backend, :final estimatedBytes) => Column(
          children: [
            _Row('Modèle', name),
            _Row('Unité', backend.label),
            _Row('Empreinte estimée', formatBytes(estimatedBytes)),
          ],
        ),
      ModelError(:final message) => Text(
          message,
          style: const TextStyle(color: NoriaColors.danger, fontWeight: FontWeight.w700),
        ),
    };
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: NoriaTheme.mono, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
