// Archivo: lib/widgets/credito/pestaña_descargables.dart

import 'dart:typed_data';
import 'dart:io';
import 'package:finora_app/helpers/pdf_exporter_controlpago.dart';
import 'package:finora_app/helpers/pdf_exporter_cuentaspago.dart';
import 'package:finora_app/helpers/pdf_resumen_credito.dart';
import 'package:finora_app/ip.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:finora_app/models/creditos.dart';
import 'package:finora_app/providers/theme_provider.dart';
import '../../utils/app_logger.dart';
import 'package:finora_app/helpers/save_file.dart';



// ----- NUEVOS IMPORTS PARA LA COMPATIBILIDAD WEB -----
//import 'package:flutter/foundation.dart' show kIsWeb;
// dart:html solo se importará en web, evitando errores de compilación en móvil.
//import 'dart:html' as html;
// --------------------------------------------------------

class PaginaDescargablesMobile extends StatefulWidget {
  final Credito credito;

  const PaginaDescargablesMobile({
    Key? key,
    required this.credito,
  }) : super(key: key);

  @override
  State<PaginaDescargablesMobile> createState() => _PaginaDescargablesMobileState();
}

class _PaginaDescargablesMobileState extends State<PaginaDescargablesMobile> {
  String? _documentoDescargando;
  bool _isGenerating = false;

  /// NUEVA FUNCIÓN UNIVERSAL PARA GUARDAR/DESCARGAR ARCHIVOS
  /// Recibe los bytes del archivo y el nombre, y decide qué hacer
  /// según la plataforma (web o nativa).
 /*  Future<void> _guardarYProcesarArchivo(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      // --- LÓGICA PARA WEB ---
      // Creamos un "ancla" <a> en el HTML para iniciar la descarga.
      final anchor = html.AnchorElement(
          href: Uri.dataFromBytes(bytes, mimeType: 'application/octet-stream')
              .toString())
        ..setAttribute("download", fileName)
        ..click(); // Simula un clic para descargar
    } else {
      // --- LÓGICA PARA NATIVO (MÓVIL/ESCRITORIO) ---
      // 1. Obtener la ruta para guardar el archivo
      final directory = await getApplicationDocumentsDirectory();
      final savePath = '${directory.path}/$fileName';

      // 2. Escribir los bytes en un archivo
      final file = File(savePath);
      await file.writeAsBytes(bytes);

      // 3. Abrir el archivo con una app externa
      await _abrirArchivoGuardado(savePath);
    }
  } */

  /// Función para descargar documentos (DOCX) desde el servidor.
  Future<void> _descargarDocumento(String documento) async {
    if (_documentoDescargando != null) return;
    setState(() => _documentoDescargando = documento);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenauth') ?? '';
      if (token.isEmpty) {
        _mostrarError('Token no encontrado. Por favor, inicia sesión de nuevo.');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/formato/${documento.toLowerCase()}/${widget.credito.tipo.toLowerCase()}/${widget.credito.folio.toUpperCase()}'),
        headers: {'tokenauth': token},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final fileName = '${documento}_${widget.credito.folio}.docx';
        // Usamos nuestra nueva función universal para manejar la descarga/guardado.
        await saveFilePlatform(response.bodyBytes, fileName);
      } else {
        _mostrarError('Error del servidor: ${response.statusCode}. Inténtalo de nuevo.');
      }
    } catch (e) {
      if (mounted) _mostrarError('Error de red: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _documentoDescargando = null);
      }
    }
  }

  /// Función para generar PDFs localmente.
  Future<void> _generarPdf(
    String tipoDocumento,
    // La función generadora ahora debe devolver Future<Uint8List>
    Future<Uint8List> Function(BuildContext, Credito) generador,
  ) async {
    if (_isGenerating) return;
    _isGenerating = true;
    setState(() => _documentoDescargando = tipoDocumento);

    try {
      // 1. Llama al generador para obtener los bytes del PDF.
      final Uint8List pdfBytes = await generador(context, widget.credito);
      final fileName = '${tipoDocumento}_${widget.credito.folio}.pdf';

      // 2. Usa nuestra función universal para manejar la descarga/guardado.
      await saveFilePlatform(pdfBytes, fileName);

    } catch (e, s) {
      AppLogger.log('<<<<< ERROR AL GENERAR PDF: $tipoDocumento >>>>>\n$e\n$s');
      if (mounted) {
        _mostrarError('Error al generar el documento: $tipoDocumento.');
      }
    } finally {
      if (mounted) {
        setState(() => _documentoDescargando = null);
      }
      _isGenerating = false;
    }
  }

  // --- HELPERS (Ayudantes) ---

  // Esta función solo se usa en nativo, por lo que no necesita cambios.
  Future<void> _abrirArchivoGuardado(String path) async {
    try {
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done) {
        _mostrarError('No se pudo abrir el archivo: ${result.message}');
      }
    } catch (e) {
      _mostrarError('Error al intentar abrir el archivo. Asegúrate de tener una app para leer este formato.');
    }
  }

  // Sin cambios aquí.
  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // --- UI (Interfaz de Usuario) ---

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          _buildBotonDescarga(
            titulo: 'Contrato',
            icono: Icons.description_outlined,
            color: const Color(0xFF2962FF), // Azul
            documento: 'contrato',
            onTap: () => _descargarDocumento('contrato'),
          ),
          const SizedBox(height: 16),
          _buildBotonDescarga(
            titulo: 'Pagaré',
            icono: Icons.monetization_on_outlined,
            color: const Color(0xFF00C853), // Verde
            documento: 'pagare',
            onTap: () => _descargarDocumento('pagare'),
          ),
          const SizedBox(height: 16),
          _buildBotonDescarga(
            titulo: 'Control de Pagos',
            icono: Icons.table_chart_outlined,
            color: const Color(0xFFAA00FF), // Morado
            documento: 'control_pagos',
            // La llamada a _generarPdf ahora pasa la referencia a la función.
            onTap: () => _generarPdf('control_pagos', PDFControlPagos.generar),
          ),
          const SizedBox(height: 16),
          _buildBotonDescarga(
            titulo: 'Ficha de Pago',
            icono: Icons.receipt_long_outlined,
            color: const Color(0xFFFF6D00), // Naranja
            documento: 'ficha_pago',
            onTap: () => _generarPdf('ficha_pago', PDFCuentasPago.generar),
          ),
          const SizedBox(height: 16),
          _buildBotonDescarga(
            titulo: 'Resumen de Crédito',
            icono: Icons.picture_as_pdf_outlined,
            color: const Color(0xFF00BFA5), // Teal
            documento: 'resumen_credito',
            onTap: () => _generarPdf('resumen_credito', PDFResumenCredito.generar),
          ),
        ],
      ),
    );
  }

  // Sin cambios aquí.
  Widget _buildBotonDescarga({
  required String titulo,
  required IconData icono,
  required Color color,
  required String documento,
  required VoidCallback onTap,
}) {
  final theme = Provider.of<ThemeProvider>(context).colors;
  final estaDescargando = _documentoDescargando == documento;

  // MouseRegion sigue siendo el padre de todo para controlar el cursor.
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      // La decoración se queda en el Container.
      decoration: BoxDecoration(
        color: theme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      // Usamos `clipBehavior` para asegurarnos de que el InkWell no se "salga" de los bordes redondeados.
      clipBehavior: Clip.antiAlias, 
      child: Material( // IMPORTANTE: El Material es necesario para que el InkWell se dibuje correctamente.
        color: Colors.transparent, // El color es transparente para que se vea el fondo del AnimatedContainer.
        child: InkWell(
          // El InkWell ahora está DENTRO del contenedor.
          onTap: estaDescargando ? null : onTap,
        /*   hoverColor: color.withOpacity(0.1), // Ahora el hover sí será visible.
          splashColor: color.withOpacity(0.2), // Y el splash también. */
          hoverColor: Color(0xFF2962FF).withOpacity(0.1), // Color de hover
          splashColor: Color(0xFF2962FF).withOpacity(0.2), // Color de splash
          
          child: Padding(
            // Movemos el padding aquí, al hijo del InkWell.
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (estaDescargando)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
                  )
                else
                  Icon(Icons.download_for_offline_outlined, color: theme.textSecondary, size: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}


/*
otra duda, tengo esto y funciona bien para descargar archivos para   windows, Mac, iOS, etc, pero para web me da error:
*/