import 'dart:typed_data';
import 'dart:html' as html;

// Implementación de guardado para la WEB
Future<void> saveFilePlatform(Uint8List bytes, String fileName) async {
  final anchor = html.AnchorElement(
      href: Uri.dataFromBytes(bytes, mimeType: 'application/octet-stream').toString())
    ..setAttribute("download", fileName)
    ..click();
}