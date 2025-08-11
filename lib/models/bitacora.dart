// ========================================================================
// MODELOS DE DATOS
// ========================================================================

// --- Modelo para una entrada de la bitácora ---
import 'package:intl/intl.dart';
import '../utils/app_logger.dart';


class Bitacora {
  final String usuario;
  final String nombreCompleto;
  final String accion;
  final String? nombreAfectado; // Puede ser nulo
  final DateTime createAt;

  Bitacora({
    required this.usuario,
    required this.nombreCompleto,
    required this.accion,
    this.nombreAfectado,
    required this.createAt,
  });

  factory Bitacora.fromJson(Map<String, dynamic> json) {
    // Función para parsear la fecha de forma segura
    DateTime parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return DateTime.now();
      try {
        // Formato que usa tu API de escritorio: 'dd/MM/yyyy hh:mm a'
        return DateFormat('dd/MM/yyyy hh:mm a', 'en_US').parse(dateString.trim());
      } catch (e) {
        // Intenta con formato ISO 8601 como respaldo
        try {
          return DateTime.parse(dateString);
        } catch (_) {
          // Si todo falla, devuelve la fecha actual
          AppLogger.log('Error al parsear fecha en bitácora: "$dateString"');
          return DateTime.now();
        }
      }
    }

    return Bitacora(
      usuario: json['usuario'] ?? 'N/A',
      nombreCompleto: json['nombreCompleto'] ?? 'Nombre no disponible',
      accion: json['accion'] ?? 'Acción no especificada',
      nombreAfectado: json['nombreAfectado'],
      createAt: parseDate(json['createAt']),
    );
  }
}
