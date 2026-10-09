import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/memory_channel.dart';
import '../domain/memory_snapshot.dart';
import '../domain/ram_guard.dart';

const memoryPollInterval = Duration(seconds: 1);

final memoryChannelProvider = Provider<MemoryChannel>((ref) => const MemoryChannel());

final ramGuardProvider = Provider<RamGuard>((ref) => const RamGuard());

/// Live memory feed. `autoDispose` stops polling when nothing listens.
final memorySnapshotProvider = StreamProvider.autoDispose<MemorySnapshot>((ref) async* {
  final channel = ref.watch(memoryChannelProvider);
  yield await channel.read();
  yield* Stream.periodic(memoryPollInterval).asyncMap((_) => channel.read());
});
