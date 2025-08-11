// archivo: moratorios.dart

class Moratorios {
  double montoTotal;
  double moratorios; // Esta es la propiedad que el resto del código espera
  int semanasDeRetraso;
  int diferenciaEnDias;
  String mensaje;

  Moratorios({
    required this.montoTotal,
    required this.moratorios,
    required this.semanasDeRetraso,
    required this.diferenciaEnDias,
    required this.mensaje,
  });

  factory Moratorios.fromJson(Map<String, dynamic> json) {
    // Es buena práctica manejar los tipos de datos de forma segura
    return Moratorios(
      montoTotal: (json['montoTotal'] as num?)?.toDouble() ?? 0.0,
      moratorios: (json['moratorios'] as num?)?.toDouble() ?? 0.0,
      semanasDeRetraso: json['semanasDeRetraso'] as int? ?? 0,
      diferenciaEnDias: json['diferenciaEnDias'] as int? ?? 0,
      mensaje: json['mensaje'] as String? ?? '',
    );
  }
}