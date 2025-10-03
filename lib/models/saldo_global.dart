// lib/models/saldo_global.dart

class SaldoGlobal {
  final String idsaldoglobal;
  final double totalSaldoGlobal;
  final DateTime fechaCreacion;

  SaldoGlobal({
    required this.idsaldoglobal,
    required this.totalSaldoGlobal,
    required this.fechaCreacion,
  });

  /// Factory constructor para crear una instancia de SaldoGlobal desde un mapa JSON.
  factory SaldoGlobal.fromJson(Map<String, dynamic> json) {
    return SaldoGlobal(
      idsaldoglobal: json['idsaldoglobal'] ?? '',
      totalSaldoGlobal: (json['totalSaldoGlobal'] as num?)?.toDouble() ?? 0.0,
      // Se intenta parsear la fecha, si falla o es nula, se usa la fecha actual.
      fechaCreacion:
          DateTime.tryParse(json['fechaCreacion'] ?? '') ?? DateTime.now(),
    );
  }
}
