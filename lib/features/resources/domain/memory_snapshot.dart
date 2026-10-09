import 'package:flutter/foundation.dart';

@immutable
class MemorySnapshot {
  const MemorySnapshot({
    required this.totalBytes,
    required this.availableBytes,
    required this.appBytes,
    required this.lowMemory,
    this.chip,
  });

  factory MemorySnapshot.fromMap(Map<String, Object?> map) {
    int asInt(String key) => (map[key] as num?)?.toInt() ?? -1;
    return MemorySnapshot(
      totalBytes: asInt('totalBytes'),
      availableBytes: asInt('availableBytes'),
      appBytes: asInt('appBytes'),
      lowMemory: map['lowMemory'] as bool? ?? false,
      chip: map['chip'] as String?,
    );
  }

  final int totalBytes;

  /// Memory the OS reports as available to allocate. On iOS this is
  /// `os_proc_available_memory()` (per-process budget before jetsam).
  final int availableBytes;

  /// Footprint of the Noria process (PSS on Android, phys_footprint on iOS).
  final int appBytes;

  final bool lowMemory;
  final String? chip;

  int get usedBytes => totalBytes - availableBytes;

  double get usedRatio => totalBytes > 0 ? usedBytes / totalBytes : 0;
}
