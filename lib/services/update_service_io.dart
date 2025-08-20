// lib/services/update_service_io.dart

import 'package:flutter/material.dart';

// Implementación "falsa" o vacía para plataformas no web (móvil, escritorio).
class UpdateService {
  // Siempre será 'false' ya que no hay actualizaciones de PWA aquí.
  final ValueNotifier<bool> isUpdateAvailable = ValueNotifier(false);

  UpdateService(); // Constructor vacío

  // Nuevo método "falso". Debe existir para que el código en main.dart compile,
  // pero no hará nada en plataformas que no sean web.
  Future<void> checkForUpdate() async {
    // No hacer nada.
    return;
  }

  // Este método no hará nada en plataformas de escritorio o móvil.
  void activateNewVersion() {
    // No hacer nada.
    return;
  }

  // Libera el ValueNotifier para evitar fugas de memoria.
  void dispose() {
    isUpdateAvailable.dispose();
  }
}