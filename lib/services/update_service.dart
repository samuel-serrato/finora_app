// services/update_service.dart

import 'dart:js_util'; // Necesario para la interoperabilidad con JS
import 'dart:html';    // Necesario para window, document, etc.
import 'package:flutter/material.dart';

class UpdateService {
  final ValueNotifier<bool> isUpdateAvailable = ValueNotifier(false);

  UpdateService() {
    _initialize();
  }

  void _initialize() {
    document.addEventListener('new-version-ready', (event) {
      isUpdateAvailable.value = true;
    });
  }

  void activateNewVersion() {
    callMethod(window, 'activateNewWorker', []);

    // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
    // Se accede al Service Worker a través de `window.navigator`.
    window.navigator.serviceWorker?.addEventListener('controllerchange', (event) {
      // Una vez que el nuevo controlador está activo, recargamos la página.
      window.location.reload();
    });
  }
}