import 'inference_mode.dart';

/// Contract for the native local runtime. Phase 2 replaces [StubLocalEngine]
/// with FFI bindings to llama.cpp / LiteRT-LM.
abstract interface class LocalInferenceEngine {
  bool get isLoaded;

  Future<void> load(String modelPath, {ComputeBackend backend = ComputeBackend.cpu});

  /// Frees the context, KV cache and weights held by the native runtime.
  Future<void> eject();
}

class StubLocalEngine implements LocalInferenceEngine {
  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load(String modelPath, {ComputeBackend backend = ComputeBackend.cpu}) async {
    _loaded = true;
  }

  @override
  Future<void> eject() async {
    _loaded = false;
  }
}
