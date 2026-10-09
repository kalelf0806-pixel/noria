import 'package:flutter/foundation.dart';

import 'memory_snapshot.dart';

enum GuardVerdict { allow, warn, block }

@immutable
class RamGuardResult {
  const RamGuardResult({
    required this.verdict,
    required this.estimatedBytes,
    required this.ratioOfTotal,
    required this.reason,
  });

  final GuardVerdict verdict;
  final int estimatedBytes;
  final double ratioOfTotal;
  final String reason;
}

/// Pre-load check for local models.
///
/// The estimate is `fileSize * overheadFactor + contextBytes`: GGUF weights are
/// mmapped close to their on-disk size, plus runtime buffers and the KV cache.
class RamGuard {
  const RamGuard({
    this.warnRatio = 0.5,
    this.blockRatio = 0.6,
    this.overheadFactor = 1.2,
  });

  final double warnRatio;
  final double blockRatio;
  final double overheadFactor;

  RamGuardResult evaluate({
    required int modelFileBytes,
    required MemorySnapshot snapshot,
    int contextBytes = 0,
  }) {
    final estimated = (modelFileBytes * overheadFactor).round() + contextBytes;

    if (snapshot.totalBytes <= 0) {
      return RamGuardResult(
        verdict: GuardVerdict.block,
        estimatedBytes: estimated,
        ratioOfTotal: 0,
        reason: 'RAM totale inconnue : chargement refusé par sécurité.',
      );
    }

    final ratio = estimated / snapshot.totalBytes;

    if (ratio > blockRatio) {
      return RamGuardResult(
        verdict: GuardVerdict.block,
        estimatedBytes: estimated,
        ratioOfTotal: ratio,
        reason: 'Le modèle dépasse ${(blockRatio * 100).round()} % de la RAM totale.',
      );
    }

    if (snapshot.availableBytes >= 0 && estimated > snapshot.availableBytes) {
      return RamGuardResult(
        verdict: GuardVerdict.block,
        estimatedBytes: estimated,
        ratioOfTotal: ratio,
        reason: 'RAM disponible insuffisante en ce moment.',
      );
    }

    if (ratio >= warnRatio) {
      return RamGuardResult(
        verdict: GuardVerdict.warn,
        estimatedBytes: estimated,
        ratioOfTotal: ratio,
        reason: 'Le modèle occupera plus de ${(warnRatio * 100).round()} % de la RAM totale.',
      );
    }

    return RamGuardResult(
      verdict: GuardVerdict.allow,
      estimatedBytes: estimated,
      ratioOfTotal: ratio,
      reason: 'Marge mémoire suffisante.',
    );
  }
}
