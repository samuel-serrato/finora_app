class RenovacionPendiente {
  final String idfechaspagos;
  final String iddetallegrupos;
  final String idgrupos;
  final String idclientes;
  final String grupo;
  final String nombreCliente;
  final double descuento;

  RenovacionPendiente({
    required this.idfechaspagos,
    required this.iddetallegrupos,
    required this.idgrupos,
    required this.idclientes,
    required this.grupo,
    required this.nombreCliente,
    required this.descuento,
  });

  factory RenovacionPendiente.fromJson(Map<String, dynamic> json) {
    return RenovacionPendiente(
      idfechaspagos: json['idfechaspagos'] ?? '',
      iddetallegrupos: json['iddetallegrupos'] ?? '',
      idgrupos: json['idgrupos'] ?? '',
      idclientes: json['idclientes'] ?? '',
      grupo: json['grupo'] ?? '',
      nombreCliente: json['nombreCliente'] ?? '',
      descuento: (json['descuento'] as num? ?? 0).toDouble(),
    );
  }
}