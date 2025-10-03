// lib/models/calendario_response.dart

import 'package:finora_app/models/pago.dart';        // Asegúrate que la ruta sea correcta
import 'package:finora_app/models/saldo_global.dart'; // Asegúrate que la ruta sea correcta

class CalendarioResponse {
  final List<SaldoGlobal> saldosGlobales;
  final List<Pago> pagos;

  CalendarioResponse({
    required this.saldosGlobales,
    required this.pagos,
  });
}