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

  factory EstadoCredito.fromJson(Map<String, dynamic> json) {
  // Manejo de seguridad si el JSON entero es nulo o vacío
  if (json.isEmpty) {
    return EstadoCredito(
      montoTotal: 0.0,
      moratorios: 0.0,
      semanasDeRetraso: 0,
      diferenciaEnDias: 0,
      acumulado: 0,
      mensaje: '',
      estado: '',
    );
  }

  return EstadoCredito(
    // 1. Convertir de forma segura a double, con valor por defecto 0.0 si es nulo
    montoTotal: (json['montoTotal'] as num?)?.toDouble() ?? 0.0,
    moratorios: (json['moratorios'] as num?)?.toDouble() ?? 0.0,

    // 2. Asignar de forma segura a int, con valor por defecto 0 si es nulo
    semanasDeRetraso: json['semanasDeRetraso'] ?? 0,
    diferenciaEnDias: json['diferenciaEnDias'] ?? 0,

    // 3. Asignar de forma segura a String, con valor por defecto '' si es nulo
    mensaje: json['mensaje'] ?? '',

    // 4. Buscar en 'estado' y 'esatado' (si es un typo común en tu API)
    estado: json['estado'] ?? json['esatado'] ?? '',

    // 5. Asegurar que acumulado sea un entero, con valor por defecto 0 si es nulo
    acumulado: json['acumulado'] ?? 0,
  );
}
}
