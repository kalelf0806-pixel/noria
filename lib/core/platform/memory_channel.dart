import 'package:flutter/services.dart';

import '../../features/resources/domain/memory_snapshot.dart';

/// Bridge to the native memory probes implemented in
/// `MainActivity.kt` (Android) and `AppDelegate.swift` (iOS).
class MemoryChannel {
  const MemoryChannel();

  static const _channel = MethodChannel('app.noria/memory');

  Future<MemorySnapshot> read() async {
    final map = await _channel.invokeMapMethod<String, Object?>('getMemoryInfo');
    if (map == null) {
      throw StateError('Native memory probe returned no data');
    }
    return MemorySnapshot.fromMap(map);
  }
}
