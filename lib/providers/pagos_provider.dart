import 'package:flutter/material.dart';
import 'package:finora_app/models/pago_seleccionado.dart';
import 'package:uuid/uuid.dart'; // Asegúrate de añadir esta dependencia si usas UUID
import 'package:collection/collection.dart'; // Importa para usar DeepCollectionEquality

class PagosProvider with ChangeNotifier {
  List<PagoSeleccionado> _pagosSeleccionados = [];
  List<PagoSeleccionado> _pagosOriginales =
      []; // Nueva lista para los pagos originales

  List<PagoSeleccionado> get pagosSeleccionados => _pagosSeleccionados;
  List<PagoSeleccionado> get pagosOriginales =>
      _pagosOriginales; // Getter público

  bool hayCambios() {
    return obtenerCamposModificados().isNotEmpty;
  }

  // Método para cargar los pagos
  void cargarPagos(List<PagoSeleccionado> pagos) {
    _pagosSeleccionados = List.from(pagos);
    _pagosOriginales =
        List.from(pagos); // Haz una copia idéntica de los originales
    notifyListeners();
  }

  // Método para obtener los pagos modificados
  final DeepCollectionEquality _equality = DeepCollectionEquality();

  List<Map<String, dynamic>> obtenerCamposModificados() {
    List<Map<String, dynamic>> pagosModificados = [];

    // Validar si las listas tienen el mismo tamaño
    if (_pagosSeleccionados.length != _pagosOriginales.length) {
      throw Exception(
          'La longitud de pagosSeleccionados (${_pagosSeleccionados.length}) no coincide con pagosOriginales (${_pagosOriginales.length})');
    }

    for (int i = 0; i < _pagosSeleccionados.length; i++) {
      PagoSeleccionado pagoOriginal = _pagosOriginales[i];
      PagoSeleccionado pagoActual = _pagosSeleccionados[i];

      Map<String, dynamic> camposModificados = {};

      if (pagoActual.tipoPago != pagoOriginal.tipoPago) {
        camposModificados['tipoPago'] = pagoActual.tipoPago;
      }

      if (pagoActual.deposito != pagoOriginal.deposito) {
        camposModificados['deposito'] = pagoActual.deposito;
      }
      if (pagoActual.capitalMasInteres != pagoOriginal.capitalMasInteres) {
        camposModificados['capitalMasInteres'] = pagoActual.capitalMasInteres;
      }
      if (pagoActual.saldoFavor != pagoOriginal.saldoFavor) {
        camposModificados['saldoFavor'] = pagoActual.saldoFavor;
      }
      if (pagoActual.moratorio != pagoOriginal.moratorio) {
        camposModificados['moratorio'] = pagoActual.moratorio;
      }
      if (pagoActual.saldoEnContra != pagoOriginal.saldoEnContra) {
        camposModificados['saldoEnContra'] = pagoActual.saldoEnContra;
      }
      if (pagoActual.abonos != pagoOriginal.abonos) {
        camposModificados['abonos'] = pagoActual.abonos;
      }

      if (camposModificados.isNotEmpty) {
        camposModificados['semana'] = pagoActual.semana;
        camposModificados['tipoPago'] = pagoActual.tipoPago;
        pagosModificados.add(camposModificados);
      }
    }

    return pagosModificados;
  }

  // Métodos de agregar y eliminar pagos
  void agregarPago(PagoSeleccionado nuevoPago) {
    _pagosSeleccionados.add(nuevoPago);
    _pagosOriginales.add(nuevoPago); // Asegúrate de agregar también al original

    notifyListeners();
  }

  void eliminarPago(PagoSeleccionado pago) {
    int index = _pagosSeleccionados.indexWhere((p) => p.semana == pago.semana);
    if (index != -1) {
      _pagosSeleccionados.removeAt(index);
      _pagosOriginales.removeAt(index); // Elimina también del original
      notifyListeners();
    }
  }

  void limpiarPagos() {
    _pagosSeleccionados.clear();
    notifyListeners();
  }

  // Método para agregar un abono a un pago seleccionado
  void agregarAbono(int semana, Map<String, dynamic> abono) {
    var pago = _pagosSeleccionados.firstWhere(
      (p) => p.semana == semana,
      orElse: () => throw Exception('Pago no encontrado'),
    );

    if (!abono.containsKey('id')) {
      var uuid = Uuid();
      abono['id'] = uuid.v4();
    }

    bool existe = pago.abonos.any((a) => a['id'] == abono['id']);
    if (!existe) {
      pago.abonos.add(abono);
      notifyListeners();
    }
  }

 void actualizarPago(int semana, PagoSeleccionado nuevoPago) {
  int index = _pagosSeleccionados.indexWhere((p) => p.semana == semana);
  if (index != -1) {
    _pagosSeleccionados[index] = nuevoPago;
    notifyListeners();
  } else {
    throw Exception('Pago no encontrado para la semana $semana');
  }
}


  @override
  String toString() {
    return 'PagosProvider(pagosSeleccionados: $_pagosSeleccionados)';
  }
}
