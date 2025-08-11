// lib/utils/app_logger.dart

import 'package:flutter/foundation.dart';
import 'dart:developer' as developer; // Usar dart:developer es incluso mejor

class AppLogger {
  
  static void log(dynamic message) {
    if (kDebugMode) {
      // CORRECTO: Usar la función base `print()`
      print('[LOG] $message'); 
    }
  }
  
  // Opción recomendada: Usar `developer.log` que es más potente
  static void devLog(dynamic message, {String name = 'APP'}) {
      if (kDebugMode) {
          developer.log(message.toString(), name: name);
      }
  }

  static void error(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      // CORRECTO: Usar la función base `print()`
      print('================================');
      print('[ERROR] $message');
      if (error != null) {
        print('[ERROR Object] $error');
      }
      if (stackTrace != null) {
        print('[Stack Trace] $stackTrace');
      }
      print('================================');

      // O con developer.log:
      // developer.log(
      //   message.toString(),
      //   name: 'ERROR',
      //   error: error,
      //   stackTrace: stackTrace,
      // );
    }
  }
}