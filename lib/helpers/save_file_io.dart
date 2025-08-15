import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

// Implementación de guardado para IO
Future<void> saveFilePlatform(Uint8List bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final savePath = '${directory.path}/$fileName';
  final file = File(savePath);
  await file.writeAsBytes(bytes);
  
  // Abrir el archivo después de guardarlo
  await OpenFile.open(savePath);
}