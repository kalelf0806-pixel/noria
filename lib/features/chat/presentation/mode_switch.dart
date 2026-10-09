import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../inference/application/model_controller.dart';
import '../../inference/domain/inference_mode.dart';

class ModeSwitch extends ConsumerWidget {
  const ModeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(inferenceModeProvider);
    final model = ref.watch(modelControllerProvider);
    final colors = Theme.of(context).colorScheme;

    final hint = switch (mode) {
      InferenceMode.local => model is ModelLoaded ? model.name : 'aucun modèle chargé',
      InferenceMode.cloud => 'Gemini API',
    };

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline, width: NoriaTheme.borderWidth),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in InferenceMode.values)
                _Segment(
                  label: option.label,
                  selected: option == mode,
                  onTap: () => ref.read(inferenceModeProvider.notifier).select(option),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            hint,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: NoriaTheme.mono,
              fontSize: 11,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Mode $label',
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: selected ? colors.primary : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: NoriaTheme.mono,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: selected ? colors.onPrimary : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
