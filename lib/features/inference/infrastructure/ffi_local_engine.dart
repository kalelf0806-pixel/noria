import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import '../domain/inference_mode.dart';
import '../domain/local_inference_engine.dart';

// Définitions des signatures FFI
typedef NativeLoad = Int32 Function(Pointer<Utf8> path, Int32 backend);
typedef DartLoad = int Function(Pointer<Utf8> path, int backend);

typedef NativeInfer = Pointer<Utf8> Function(Pointer<Utf8> prompt);
typedef DartInfer = Pointer<Utf8> Function(Pointer<Utf8> prompt);

typedef NativeFreeString = Void Function(Pointer<Utf8> str);
typedef DartFreeString = void Function(Pointer<Utf8> str);

typedef NativeEject = Void Function();
typedef DartEject = void Function();

class FfiLocalEngine implements LocalInferenceEngine {
  DynamicLibrary? _lib;
  bool _loaded = false;

  // Cache des fonctions FFI pour éviter des lookups répétés (Gain de performance)
  DartLoad? _cachedLoadFunc;
  DartInfer? _cachedInferFunc;
  DartFreeString? _cachedFreeFunc;
  DartEject? _cachedEjectFunc;

  DynamicLibrary get lib {
    if (_lib == null) {
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('libnoria_native.so');
      } else {
        _lib = DynamicLibrary.process();
      }
    }
    return _lib!;
  }

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load(String modelPath, {ComputeBackend backend = ComputeBackend.npu}) async {
    Pointer<Utf8>? pathPtr;
    try {
      // Chargement en cache de la fonction native si ce n'est pas déjà fait
      _cachedLoadFunc ??= lib.lookupFunction<NativeLoad, DartLoad>('noria_load_model');
      
      pathPtr = modelPath.toNativeUtf8();
      final result = _cachedLoadFunc!(pathPtr, backend.index);

      if (result == 1) {
        _loaded = true;
      } else {
        _loaded = false;
        throw Exception('Échec d\'initialisation dans le runtime C++ natif.');
      }
    } catch (e) {
      _loaded = false; // Correction du bug critique : faux positif corrigé
      rethrow; // Remonte l'erreur proprement au ModelController
    } finally {
      // Garantie anti-fuite mémoire peu importe le résultat
      if (pathPtr != null) {
        malloc.free(pathPtr);
      }
    }
  }

  String infer(String prompt) {
    if (!_loaded) return 'Aucun modèle chargé en RAM.';
    
    Pointer<Utf8>? promptPtr;
    try {
      // Mise en cache des fonctions d'inférence pour optimiser la vitesse d'exécution
      _cachedInferFunc ??= lib.lookupFunction<NativeInfer, DartInfer>('noria_infer');
      _cachedFreeFunc ??= lib.lookupFunction<NativeFreeString, DartFreeString>('noria_free_string');

      promptPtr = prompt.toNativeUtf8();
      final responsePtr = _cachedInferFunc!(promptPtr);

      // Sécurité anti-crash si le pointeur C++ est nul
      if (responsePtr == nullptr) {
        return '[Runtime Natif FFI] Erreur : Réponse vide (nullptr) reçue du module natif.';
      }

      // Lecture de la réponse vers Dart
      final response = responsePtr.toDartString();

      // Libération de la mémoire allouée par le C++ et le heap Dart
      _cachedFreeFunc!(responsePtr);

      return response;
    } catch (e) {
      return '[Runtime Natif FFI] Erreur d\'exécution : $e';
    } finally {
      if (promptPtr != null) {
        malloc.free(promptPtr);
      }
    }
  }

  @override
  Future<void> eject() async {
    try {
      _cachedEjectFunc ??= lib.lookupFunction<NativeEject, DartEject>('noria_eject');
      _cachedEjectFunc!();
    } catch (_) {}
    
    _loaded = false;
    // Réinitialisation du cache des fonctions si besoin lors d'un rechargement complet
    _cachedLoadFunc = null;
    _cachedInferFunc = null;
    _cachedFreeFunc = null;
    _cachedEjectFunc = null;
  }
}
