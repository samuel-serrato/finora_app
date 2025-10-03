// lib/models/agenda_item.dart

import 'dart:convert';

// Función para parsear una lista de AgendaItem desde un string JSON
List<AgendaItem> agendaItemFromJson(String str) => List<AgendaItem>.from(json.decode(str).map((x) => AgendaItem.fromJson(x)));

class AgendaItem {
    final String idpagosdetalles;
    final String idfechaspagos;
    final String idgrupos;
    final String idcredito;
    final String nombreGrupo;
    final String detalles;
    final String tipoGrupo;
    final int semanaPago;
    final DateTime fechasPago; // Convertido a DateTime para fácil manejo
    final double pagoPeriodo; // Convertido a double
    final String estado;

    AgendaItem({
        required this.idpagosdetalles,
        required this.idfechaspagos,
        required this.idgrupos,
        required this.idcredito,
        required this.nombreGrupo,
        required this.detalles,
        required this.tipoGrupo,
        required this.semanaPago,
        required this.fechasPago,
        required this.pagoPeriodo,
        required this.estado,
    });

    factory AgendaItem.fromJson(Map<String, dynamic> json) {
      return AgendaItem(
        idpagosdetalles: json["idpagosdetalles"] ?? '',
        idfechaspagos: json["idfechaspagos"] ?? '',
        idgrupos: json["idgrupos"] ?? '',
        idcredito: json["idcredito"] ?? '',
        nombreGrupo: json["nombreGrupo"] ?? 'Sin Nombre',
        detalles: json["detalles"] ?? '',
        tipoGrupo: json["tipoGrupo"] ?? 'Desconocido',
        // El campo 'SemanaPago' puede venir como String o int
        semanaPago: json["SemanaPago"] is String 
                    ? int.tryParse(json["SemanaPago"]) ?? 0 
                    : json["SemanaPago"] ?? 0,
        // Convertimos el string de fecha a un objeto DateTime
        fechasPago: DateTime.parse(json["fechasPago"]),
        // Convertimos el string de pago a un double, manejando posibles errores
        pagoPeriodo: double.tryParse(json["pagoPeriodo"] ?? '0.0') ?? 0.0,
        estado: json["estado"] ?? 'Desconocido',
      );
    }
}