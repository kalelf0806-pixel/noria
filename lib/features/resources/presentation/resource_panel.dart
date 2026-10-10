import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/hardware_evaluator.dart';
import '../../inference/application/model_controller.dart';
import '../application/resource_providers.dart';

class ResourcePanel extends ConsumerWidget {
  const ResourcePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourceState = ref.watch(resourceNotifierProvider);
    final modelState = ref.watch(modelControllerProvider);

    final activeHardware = HardwareEvaluator.evaluate(
      modelPath: modelState.currentModelPath,
      isLoaded: modelState.isLoaded,
      chipName: "Qualcomm SM8350",
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          const Text(
            'TÉLÉMÉTRIE MATÉRIELLE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          _buildRow('Empreinte Process (RSS)', '${resourceState.rssMb.toStringAsFixed(1)} Mo'),
          _buildRow('RAM Utilisée / Total', '${resourceState.usedRamMb.toStringAsFixed(1)} Mo / ${resourceState.totalRamMb.toStringAsFixed(1)} Mo'),
          _buildRow('RAM Disponible', '${resourceState.availableRamMb.toStringAsFixed(1)} Mo'),
          _buildRow('Alerte Basse Mémoire', resourceState.isLowMemory ? 'OUI (Alerte)' : 'NON (Stable)'),
          _buildRow('SoC / Chipset', 'Qualcomm SM8350'),
          _buildRow('Unité de Calcul Active', activeHardware),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
