import 'package:flutter/material.dart';

// Implementación "falsa" o vacía para plataformas no web
class UpdateService {
  // Siempre será 'false' ya que no hay actualizaciones de PWA aquí.
  final ValueNotifier<bool> isUpdateAvailable = ValueNotifier(false);

  UpdateService(); // Constructor vacío

  // Este método no hará nada en plataformas de escritorio o móvil.
  Future<void> activateNewVersion() async {
    // No hacer nada.
    return;
  }


  // AÑADE ESTE MÉTODO
  void dispose() {
    // Libera el ValueNotifier para evitar fugas de memoria.
    isUpdateAvailable.dispose();
  }
}