import 'package:package_info_plus/package_info_plus.dart';

/// Función para obtener la versión local directamente desde package_info_plus
Future<String> getLocalVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version; // Devuelve la versión definida en tu pubspec.yaml
}
