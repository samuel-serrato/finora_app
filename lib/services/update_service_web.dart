// lib/services/update_service_web.dart
import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
external void applyUpdate();

class UpdateService {
  final ValueNotifier<bool> isUpdateAvailable = ValueNotifier(false);

  UpdateService() {
    if (kIsWeb) {
      _initializeJavaScriptBridge();
    }
  }

  // En lib/services/update_service_web.dart
void _initializeJavaScriptBridge() {
  final dartCallback = () {
    // ESTA ES LA LÍNEA QUE ARREGLA EL TEMA CONGELADO
    Future(() {
      isUpdateAvailable.value = true;
    });
  };
  setProperty(globalThis, 'onNewVersionReady', allowInterop(dartCallback));
}

  Future<void> activateNewVersion() async {
    if (kIsWeb) {
      print('Dart le está diciendo a JS que aplique la actualización ahora.');
      applyUpdate();
    }
  }

  void dispose() {
    isUpdateAvailable.dispose();
  }
}