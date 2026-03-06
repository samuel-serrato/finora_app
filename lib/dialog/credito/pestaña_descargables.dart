// Archivo: lib/widgets/credito/pestaña_descargables.dart

import 'dart:typed_data';
import 'dart:io';
// 1. IMPORTS NUEVOS NECESARIOS
import 'package:finora_app/services/pago_service.dart'; // <--- Para bajar los pagos
import 'package:finora_app/models/pago.dart'; // <--- Modelo Pago
import 'package:finora_app/models/calendario_response.dart'; // <--- Respuesta API

import 'package:finora_app/helpers/pdf_exporter_controlpago.dart';
import 'package:finora_app/helpers/pdf_exporter_cuentaspago.dart';
import 'package:finora_app/helpers/pdf_resumen_credito.dart';
import 'package:finora_app/ip.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:finora_app/models/creditos.dart';
import 'package:finora_app/providers/theme_provider.dart';
import '../../utils/app_logger.dart';
import 'package:finora_app/helpers/save_file.dart';

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
  
  // 2. INSTANCIA DEL SERVICIO
  final PagoService _pagoService = PagoService(); 

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

   /// Función GENÉRICA para generar PDFs simples (Resumen, Ficha)
  Future<void> _generarPdfSimple(
    String tipoDocumento,
    Future<Uint8List> Function(BuildContext, Credito) generador,
  ) async {
    if (_isGenerating) return;
    _isGenerating = true;
    setState(() => _documentoDescargando = tipoDocumento);

    try {
      final Uint8List pdfBytes = await generador(context, widget.credito);
      
      // 1. Obtener la fecha actual formateada (ej. 24-10-2023)
      final String fecha = DateFormat('dd-MM-yyyy').format(DateTime.now());
      
      // 2. Construir el nombre base con la fecha
      final String nombreBase = '${tipoDocumento}_${widget.credito.nombreGrupo}_$fecha';
      
      // 3. Convertir todo a mayúsculas y concatenar la extensión en minúscula (recomendado)
      final String fileName = '${nombreBase.toUpperCase()}.pdf';
      
      await saveFilePlatform(pdfBytes, fileName);
    } catch (e, s) {
      AppLogger.log('ERROR PDF SIMPLE: $e\n$s');
      if (mounted) _mostrarError('Error al generar $tipoDocumento.');
    } finally {
      if (mounted) setState(() => _documentoDescargando = null);
      _isGenerating = false;
    }
  }

  // 3. NUEVA FUNCIÓN ESPECÍFICA PARA CONTROL DE PAGOS
  // Esta función descarga los datos actualizados y luego genera el PDF
  Future<void> _descargarControlPagos() async {
    if (_isGenerating) return;
    _isGenerating = true;
    setState(() => _documentoDescargando = 'control_pagos');

    try {
      // A. Descargar los pagos desde la API para tener las fechas correctas
      final response = await _pagoService.getCalendarioPagos(widget.credito.idcredito);
      
      if (!response.success || response.data == null) {
        throw 'No se pudieron obtener los datos del calendario.';
      }

      final List<Pago> listaPagos = response.data!.pagos;

      // B. Generar el PDF pasando la lista de pagos
      final Uint8List pdfBytes = await PDFControlPagos.generar(
        context, 
        widget.credito, 
        listaPagos // <--- Aquí pasamos la lista que acabamos de descargar
      );

      final fileName = 'control_pagos_${widget.credito.folio}.pdf';
      await saveFilePlatform(pdfBytes, fileName);

    } catch (e) {
      AppLogger.log('ERROR PDF CONTROL PAGOS: $e');
      if (mounted) _mostrarError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _documentoDescargando = null);
      _isGenerating = false;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          _buildBotonDescarga(
            titulo: 'Contrato',
            icono: Icons.description_outlined,
            color: const Color(0xFF2962FF),
            documento: 'contrato',
            onTap: () => _descargarDocumento('contrato'),
          ),
          const SizedBox(height: 16),
          _buildBotonDescarga(
            titulo: 'Pagaré',
            icono: Icons.monetization_on_outlined,
            color: const Color(0xFF00C853),
            documento: 'pagare',
            onTap: () => _descargarDocumento('pagare'),
          ),
          const SizedBox(height: 16),
          
          // --- AQUÍ ESTÁ EL CAMBIO EN EL BOTÓN ---
          _buildBotonDescarga(
            titulo: 'Control de Pagos',
            icono: Icons.table_chart_outlined,
            color: const Color(0xFFAA00FF),
            documento: 'control_pagos',
            // Ahora llamamos a la función específica
            onTap: _descargarControlPagos, 
          ),
          
          const SizedBox(height: 16),
          _buildBotonDescarga(
            titulo: 'Ficha de Pago',
            icono: Icons.receipt_long_outlined,
            color: const Color(0xFFFF6D00),
            documento: 'ficha_pago',
            // Usamos la función simple para los que no cambiaron
            onTap: () => _generarPdfSimple('ficha_pago', PDFCuentasPago.generar),
          ),
          const SizedBox(height: 16),
          _buildBotonDescarga(
            titulo: 'Resumen de Crédito',
            icono: Icons.picture_as_pdf_outlined,
            color: const Color(0xFF00BFA5),
            documento: 'resumen_credito',
            onTap: () => _generarPdfSimple('resumen_credito', PDFResumenCredito.generar),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonDescarga({
    required String titulo,
    required IconData icono,
    required Color color,
    required String documento,
    required VoidCallback onTap,
  }) {
    final theme = Provider.of<ThemeProvider>(context).colors;
    final estaDescargando = _documentoDescargando == documento;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
        clipBehavior: Clip.antiAlias, 
        child: Material( 
          color: Colors.transparent, 
          child: InkWell(
            onTap: estaDescargando ? null : onTap,
            hoverColor: Color(0xFF2962FF).withOpacity(0.1),
            splashColor: Color(0xFF2962FF).withOpacity(0.2),
            child: Padding(
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