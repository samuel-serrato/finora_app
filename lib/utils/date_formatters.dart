// utils/date_formatters.dart
import 'package:intl/intl.dart';

class DateFormatters {
  // Parser para el formato del servidor: "13/06/2025 12:53 PM"
  static DateTime _parsearFechaServidor(String fechaString) {
    try {
      // Separamos fecha y hora
      List<String> partes = fechaString.split(' ');
      String fechaParte = partes[0]; // "13/06/2025"
      String horaParte = partes[1]; // "12:53"
      String amPm = partes[2]; // "PM"
      
      // Separamos día, mes, ano
      List<String> fechaPartes = fechaParte.split('/');
      int dia = int.parse(fechaPartes[0]);
      int mes = int.parse(fechaPartes[1]);
      int ano = int.parse(fechaPartes[2]);
      
      // Separamos hora y minutos
      List<String> horaPartes = horaParte.split(':');
      int hora = int.parse(horaPartes[0]);
      int minutos = int.parse(horaPartes[1]);
      
      // Convertimos formato 12h a 24h
      if (amPm.toUpperCase() == 'PM' && hora != 12) {
        hora += 12;
      } else if (amPm.toUpperCase() == 'AM' && hora == 12) {
        hora = 0;
      }
      
      return DateTime(ano, mes, dia, hora, minutos);
    } catch (e) {
      throw FormatException('Error al parsear fecha: $fechaString');
    }
  }

  // Formato completo: "13 de junio de 2025"
  static String formatearFechaCompleta(String fechaString) {
    try {
      DateTime fecha = _parsearFechaServidor(fechaString);
      return DateFormat('d \'de\' MMMM \'de\' y', 'es').format(fecha);
    } catch (e) {
      return fechaString;
    }
  }

  // Formato corto: "13 jun 2025"
  static String formatearFechaCorta(String fechaString) {
    try {
      DateTime fecha = _parsearFechaServidor(fechaString);
      return DateFormat('d MMM y', 'es').format(fecha);
    } catch (e) {
      return fechaString;
    }
  }

  // Solo día y mes: "13 de junio"
  static String formatearFechaDiaMes(String fechaString) {
    try {
      DateTime fecha = _parsearFechaServidor(fechaString);
      return DateFormat('d \'de\' MMMM', 'es').format(fecha);
    } catch (e) {
      return fechaString;
    }
  }

  // Con día de la semana: "viernes, 13 de junio de 2025"
  static String formatearFechaConDia(String fechaString) {
    try {
      DateTime fecha = _parsearFechaServidor(fechaString);
      return DateFormat('EEEE, d \'de\' MMMM \'de\' y', 'es').format(fecha);
    } catch (e) {
      return fechaString;
    }
  }

  // Formato relativo: "hace 2 días", "ayer", "hoy"
  static String formatearFechaRelativa(String fechaString) {
    try {
      DateTime fecha = _parsearFechaServidor(fechaString);
      DateTime ahora = DateTime.now();
      Duration diferencia = ahora.difference(fecha);

      if (diferencia.inDays == 0) {
        return 'Hoy';
      } else if (diferencia.inDays == 1) {
        return 'Ayer';
      } else if (diferencia.inDays < 7) {
        return 'Hace ${diferencia.inDays} días';
      } else if (diferencia.inDays < 20) {
        int semanas = (diferencia.inDays / 7).floor();
        return semanas == 1 ? 'Hace 1 semana' : 'Hace $semanas semanas';
      } else {
        return formatearFechaCorta(fechaString);
      }
    } catch (e) {
      return fechaString;
    }
  }

  // Solo fecha sin hora: "13/06/2025"
  static String formatearSoloFecha(String fechaString) {
    try {
      DateTime fecha = _parsearFechaServidor(fechaString);
      return DateFormat('dd/MM/y', 'es').format(fecha);
    } catch (e) {
      return fechaString.split(' ')[0]; // Devuelve solo la parte de fecha
    }
  }

  // Con hora: "13 de junio - 12:53 PM"
  static String formatearFechaConHora(String fechaString) {
    try {
      DateTime fecha = _parsearFechaServidor(fechaString);
      String fechaFormateada = DateFormat('d \'de\' MMMM', 'es').format(fecha);
      String horaFormateada = DateFormat('h:mm a', 'es').format(fecha);
      return '$fechaFormateada - $horaFormateada';
    } catch (e) {
      return fechaString;
    }
  }

  // Método genérico para formato personalizado
  static String formatearFechaPersonalizada(String fechaString, String patron) {
    try {
      DateTime fecha = _parsearFechaServidor(fechaString);
      return DateFormat(patron, 'es').format(fecha);
    } catch (e) {
      return fechaString;
    }
  }

  // Para DateTime directamente (si no viene como String)
  static String formatearDateTime(DateTime fecha, {String tipo = 'completa'}) {
    try {
      switch (tipo) {
        case 'completa':
          return DateFormat('d \'de\' MMMM \'de\' y', 'es').format(fecha);
        case 'corta':
          return DateFormat('d MMM y', 'es').format(fecha);
        case 'diaMes':
          return DateFormat('d \'de\' MMMM', 'es').format(fecha);
        case 'conDia':
          return DateFormat('EEEE, d \'de\' MMMM \'de\' y', 'es').format(fecha);
        default:
          return DateFormat('d \'de\' MMMM \'de\' y', 'es').format(fecha);
      }
    } catch (e) {
      return fecha.toString();
    }
  }
}