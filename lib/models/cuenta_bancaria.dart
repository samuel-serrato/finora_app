class CuentaBancaria {
  final String idnegocio;
  final String nombreCuenta;
  final String numeroCuenta;
  final String nombreBanco;
  final String rutaBanco;
  final DateTime fCreacion;

  CuentaBancaria({
    required this.idnegocio,
    required this.nombreCuenta,
    required this.numeroCuenta,
    required this.nombreBanco,
    required this.rutaBanco,
    required this.fCreacion,
  });

  factory CuentaBancaria.fromJson(Map<String, dynamic> json) {
    return CuentaBancaria(
      idnegocio: json['idnegocio'],
      nombreCuenta: json['nombreCuenta'],
      numeroCuenta: json['numeroCuenta'],
      nombreBanco: json['nombreBanco'],
      rutaBanco: json['rutaBanco'],
      fCreacion: DateTime.parse(json['fCreacion']),
    );
  }
}