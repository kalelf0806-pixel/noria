import 'inference_mode.dart';

abstract interface class LocalInferenceEngine {
  bool get isLoaded;

  Future<void> load(String modelPath, {ComputeBackend backend = ComputeBackend.cpu});

  Future<void> eject();

  String infer(String prompt);
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

  @override
  String infer(String prompt) {
    if (!_loaded) return '[Stub] Aucun modèle local chargé.';
    return '[Stub Local] Réponse simulée pour : "$prompt"';
  }
}
