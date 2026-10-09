import 'package:flutter_test/flutter_test.dart';
import 'package:noria/features/resources/domain/memory_snapshot.dart';
import 'package:noria/features/resources/domain/ram_guard.dart';

const gib = 1024 * 1024 * 1024;

MemorySnapshot snapshot({int total = 8 * gib, int available = 6 * gib}) => MemorySnapshot(
      totalBytes: total,
      availableBytes: available,
      appBytes: 200 * 1024 * 1024,
      lowMemory: false,
    );

void main() {
  const guard = RamGuard(overheadFactor: 1.0);

  test('allows a model below 50 % of total RAM', () {
    final result = guard.evaluate(modelFileBytes: 2 * gib, snapshot: snapshot());
    expect(result.verdict, GuardVerdict.allow);
  });

  test('warns between 50 % and 60 % of total RAM', () {
    final result = guard.evaluate(modelFileBytes: (4.4 * gib).round(), snapshot: snapshot());
    expect(result.verdict, GuardVerdict.warn);
  });

  test('blocks above 60 % of total RAM', () {
    final result = guard.evaluate(modelFileBytes: 5 * gib, snapshot: snapshot());
    expect(result.verdict, GuardVerdict.block);
  });

  test('blocks when the model exceeds currently available RAM', () {
    final result = guard.evaluate(
      modelFileBytes: 3 * gib,
      snapshot: snapshot(available: 2 * gib),
    );
    expect(result.verdict, GuardVerdict.block);
  });

  test('blocks when total RAM is unknown', () {
    final result = guard.evaluate(modelFileBytes: gib, snapshot: snapshot(total: -1));
    expect(result.verdict, GuardVerdict.block);
  });
}
