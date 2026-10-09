import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../resources/application/resource_providers.dart';
import '../../resources/domain/ram_guard.dart';
import '../domain/inference_mode.dart';
import '../domain/local_inference_engine.dart';

sealed class ModelState {
  const ModelState();
}

class ModelIdle extends ModelState {
  const ModelIdle();
}

class ModelLoading extends ModelState {
  const ModelLoading(this.name);
  final String name;
}

class ModelLoaded extends ModelState {
  const ModelLoaded({
    required this.name,
    required this.path,
    required this.backend,
    required this.estimatedBytes,
  });

  final String name;
  final String path;
  final ComputeBackend backend;
  final int estimatedBytes;
}

class ModelError extends ModelState {
  const ModelError(this.message);
  final String message;
}

final localEngineProvider = Provider<LocalInferenceEngine>((ref) => StubLocalEngine());

final inferenceModeProvider =
    NotifierProvider<InferenceModeNotifier, InferenceMode>(InferenceModeNotifier.new);

class InferenceModeNotifier extends Notifier<InferenceMode> {
  @override
  InferenceMode build() => InferenceMode.cloud;

  void select(InferenceMode mode) => state = mode;
}

final modelControllerProvider =
    NotifierProvider<ModelController, ModelState>(ModelController.new);

class ModelController extends Notifier<ModelState> {
  @override
  ModelState build() => const ModelIdle();

  LocalInferenceEngine get _engine => ref.read(localEngineProvider);

  Future<RamGuardResult> evaluate(String path) async {
    final fileBytes = await File(path).length();
    final snapshot = await ref.read(memoryChannelProvider).read();
    return ref.read(ramGuardProvider).evaluate(
          modelFileBytes: fileBytes,
          snapshot: snapshot,
        );
  }

  /// Loads a model after the caller has shown the [RamGuardResult] to the user.
  /// A blocking verdict is re-checked here so the guard cannot be bypassed.
  Future<void> load(String path, {ComputeBackend backend = ComputeBackend.cpu}) async {
    final name = path.split(Platform.pathSeparator).last;
    final guard = await evaluate(path);
    if (guard.verdict == GuardVerdict.block) {
      state = ModelError(guard.reason);
      return;
    }

    if (_engine.isLoaded) await eject();

    state = ModelLoading(name);
    try {
      await _engine.load(path, backend: backend);
      state = ModelLoaded(
        name: name,
        path: path,
        backend: backend,
        estimatedBytes: guard.estimatedBytes,
      );
    } catch (error) {
      state = ModelError('Échec du chargement : $error');
    }
  }

  Future<void> eject() async {
    await _engine.eject();
    state = const ModelIdle();
  }
}
