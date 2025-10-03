import 'package:intl/intl.dart';

String formatCurrency(num value) {
  // Si tiene decimales, mostramos 2
  if (value % 1 != 0) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  } 
  // Si no tiene decimales, mostramos 0
  else {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }
}
