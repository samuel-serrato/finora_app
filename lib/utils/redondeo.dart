import 'package:finora_app/providers/user_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

dynamic redondearDecimales(dynamic valor, BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final double umbralRedondeo = userData.redondeo;

    if (valor is double) {
      if ((valor - valor.truncateToDouble()).abs() < 0.000001) {
        return valor.truncateToDouble();
      } else {
        double parteDecimal = valor - valor.truncateToDouble();

        if (parteDecimal >= umbralRedondeo) {
          return valor.ceilToDouble();
        } else {
          return valor.floorToDouble();
        }
      }
    } else if (valor is int) {
      return valor.toDouble();
    } else if (valor is List) {
      return valor.map((e) => redondearDecimales(e, context)).toList();
    } else if (valor is Map) {
      return valor.map<String, dynamic>(
        (key, value) => MapEntry(key, redondearDecimales(value, context)),
      );
    }
    return valor;
  }