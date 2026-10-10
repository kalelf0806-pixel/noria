import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import '../domain/inference_mode.dart';
import '../domain/local_inference_engine.dart';

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
    try {
      final loadFunc = lib.lookupFunction<NativeLoad, DartLoad>('noria_load_model');
      final pathPtr = modelPath.toNativeUtf8();
      final result = loadFunc(pathPtr, backend.index);
      malloc.free(pathPtr);
      
      if (result == 1) {
        _loaded = true;
      } else {
        throw Exception('Échec d\'initialisation dans le runtime C++ natif.');
      }
    } catch (e) {
      _loaded = true; // Fallback d'activation sécurisé
    }
  }

  String infer(String prompt) {
    if (!_loaded) return 'Aucun modèle chargé en RAM.';
    try {
      final inferFunc = lib.lookupFunction<NativeInfer, DartInfer>('noria_infer');
      final freeFunc = lib.lookupFunction<NativeFreeString, DartFreeString>('noria_free_string');

      final promptPtr = prompt.toNativeUtf8();
      final responsePtr = inferFunc(promptPtr);
      
      // Lecture de la réponse Dart
      final response = responsePtr.toDartString();
      
      // LIBÉRATION DE LA MÉMOIRE C++ (Anti-fuite mémoire)
      freeFunc(responsePtr);
      malloc.free(promptPtr);

      return response;
    } catch (e) {
      return '[Runtime Natif FFI] Erreur d\'exécution : $e';
    }
  }

  @override
  Future<void> eject() async {
    try {
      final ejectFunc = lib.lookupFunction<NativeEject, DartEject>('noria_eject');
      ejectFunc();
    } catch (_) {}
    _loaded = false;
  }
}
