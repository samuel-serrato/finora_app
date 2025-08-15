// Pega esta función al inicio de tu archivo models/estado_credito.dart
double parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class EstadoCredito {
  final double montoTotal;
  final double moratorios;
  final int semanasDeRetraso;
  final int diferenciaEnDias;
  final double acumulado;
  final String mensaje;
  final String estado;

  EstadoCredito({
    required this.montoTotal,
    required this.moratorios,
    required this.semanasDeRetraso,
    required this.diferenciaEnDias,
    required this.acumulado,
    required this.mensaje,
    required this.estado,
  });

  // En tu clase EstadoCredito
factory EstadoCredito.fromJson(Map<String, dynamic> json) {
  // Manejo de seguridad si el JSON entero es nulo o vacío, esto está bien
  if (json.isEmpty) {
    return EstadoCredito(
      montoTotal: 0.0,
      moratorios: 0.0,
      semanasDeRetraso: 0,
      diferenciaEnDias: 0,
      acumulado: 0.0, // Asegúrate de que el valor por defecto sea double
      mensaje: '',
      estado: '',
    );
  }

  return EstadoCredito(
    // --- CAMPOS DOUBLE ---
    // Usa nuestra función segura para todos los `double`.
    // Esto maneja int, double, String y null sin problemas.
    montoTotal: parseDouble(json['montoTotal']),
    moratorios: parseDouble(json['moratorios']),
    acumulado: parseDouble(json['acumulado']),

    // --- CAMPOS INT ---
    // Para los `int`, tu método es bueno. Lo hacemos un poco más robusto
    // por si la API envía un número como String (ej. "3").
    semanasDeRetraso: int.tryParse(json['semanasDeRetraso']?.toString() ?? '0') ?? 0,
    diferenciaEnDias: int.tryParse(json['diferenciaEnDias']?.toString() ?? '0') ?? 0,

    // --- CAMPOS STRING ---
    // Tu método es perfecto, lo mantenemos.
    mensaje: json['mensaje'] ?? '',
    estado: json['estado'] ?? json['esatado'] ?? '', // Maneja el typo
  );
}
}
