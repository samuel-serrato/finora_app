// lib/services/update_service_web.dart

import 'package:finora_app/ip.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';

// Importa 'dart:js' para la interoperabilidad con JavaScript.
import 'dart:js' as js;

import 'dart:js_util' as js_util;

import '../utils/app_logger.dart';

class UpdateService {
  final ValueNotifier<bool> isUpdateAvailable = ValueNotifier(false);

  UpdateService() {
    js.context['onNewVersionReady'] = () {
      AppLogger.log(
        'Dart: Notificación recibida desde JS. La actualización está lista.',
      );
      Future(() {
        isUpdateAvailable.value = true;
      });
    };
  }

  Future<void> checkForUpdate() async {
    if (!kIsWeb || kDebugMode) {
      AppLogger.log(
        'Comprobación de actualización omitida (no es un build web de producción).',
      );
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // ==================== INICIO DE LA ADAPTACIÓN ====================

      // 1. CAMBIA LA URL PARA QUE APUNTE A TU ENDPOINT EXACTO
      final url = Uri.parse(
        '$baseUrl/api/v1/buscar/version/finora',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // 2. PARSEA EL JSON COMPLETO
        final serverData = json.decode(response.body);

        // 3. EXTRAE LA VERSIÓN DEL CAMPO 'version' DENTRO DEL OBJETO
        //    Asegúrate de que el tipo sea String para una comparación segura.
        final latestVersion = serverData['version'] as String;

        // ===================== FIN DE LA ADAPTACIÓN =====================

        AppLogger.log(
          'Versión actual de la app: $currentVersion, Última versión en el servidor: $latestVersion',
        );

        if (latestVersion != currentVersion) {
          AppLogger.log(
            '¡Se encontró una nueva versión! Pidiendo al navegador que busque un nuevo Service Worker.',
          );
          _triggerServiceWorkerUpdate();
        } else {
          AppLogger.log('La aplicación ya está en su última versión.');
        }
      } else {
        // Añadimos un log para errores de petición HTTP
        AppLogger.log('Error en la petición: Status code ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.log('Error al verificar la actualización: $e');
    }
  }

 // En lib/services/update_service_web.dart

void _triggerServiceWorkerUpdate() {
  // Obtenemos la Promise desde JS
  final promise = js.context['navigator']['serviceWorker'].callMethod('getRegistration');

  // La convertimos a un Future de Dart
  js_util.promiseToFuture(promise).then((registration) {
    // Verificamos que el registro del Service Worker existe
    if (registration != null) {
      AppLogger.log('Forzando la comprobación del Service Worker...');
      
      // 'registration' es ahora un objeto JS que representa el ServiceWorkerRegistration.
      // Llamamos al método 'update()' directamente sobre este objeto.
      (registration as js.JsObject).callMethod('update');
    }
  }).catchError((err) {
    // Es una buena práctica añadir un manejo de errores para estas operaciones.
    AppLogger.log('Error al intentar actualizar el Service Worker: $err');
  });
}

  void activateNewVersion() {
    AppLogger.log('Dart: Pidiendo a JS que aplique la actualización.');
    js.context.callMethod('applyUpdate');
  }

  void dispose() {
    isUpdateAvailable.dispose();
  }
}
