class ParseHelpers {
  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Eliminar comas y símbolos de moneda
      String cleanedValue =
          value.replaceAll(RegExp(r'[^0-9.]'), '').replaceAll(',', '');
      return double.tryParse(cleanedValue) ?? 0.0;
    }
    return 0.0;
  }

  static List<T> parseList<T>(dynamic data, T Function(dynamic) converter) {
    if (data == null) return [];
    if (data is! List) return [];
    try {
      return data.map((item) => converter(item)).toList();
    } catch (e) {
      return [];
    }
  }
}