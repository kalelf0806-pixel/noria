import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bytes.dart';
import '../../inference/application/model_controller.dart';
import '../application/resource_providers.dart';
import '../domain/memory_snapshot.dart';
import 'resource_panel.dart';

Color pressureColor(MemorySnapshot snapshot, Color fallback) {
  if (snapshot.lowMemory || snapshot.usedRatio > 0.85) return NoriaColors.danger;
  if (snapshot.usedRatio > 0.7) return NoriaColors.warn;
  return fallback;
}

/// Permanent app-bar badge: process RAM footprint + active compute unit.
class ResourceBadge extends ConsumerWidget {
  const ResourceBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(memorySnapshotProvider);
    final model = ref.watch(modelControllerProvider);
    final colors = Theme.of(context).colorScheme;

    final chipLabel = model is ModelLoaded ? model.backend.label : 'IDLE';
    final (ramLabel, dotColor) = switch (snapshot) {
      AsyncData(:final value) => (formatBytes(value.appBytes), pressureColor(value, NoriaColors.signal)),
      AsyncError() => ('N/A', colors.onSurfaceVariant),
      _ => ('…', colors.onSurfaceVariant),
    };

    return Semantics(
      button: true,
      label: 'Moniteur de ressources : $ramLabel utilisés, unité $chipLabel',
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    _ResourcePageHeader(),
                    Expanded(child: ResourcePanel()),
                  ],
                ),
              ),
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline, width: NoriaTheme.borderWidth),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, color: dotColor),
              const SizedBox(width: 8),
              Text(
                '$ramLabel · $chipLabel',
                style: const TextStyle(
                  fontFamily: NoriaTheme.mono,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourcePageHeader extends StatelessWidget {
  const _ResourcePageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'RESSOURCES & CONFIG',
            style: TextStyle(
              fontFamily: NoriaTheme.mono,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
