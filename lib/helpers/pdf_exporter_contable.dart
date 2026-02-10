// lib/helpers/pdf_exporter_contable.dart

import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:finora_app/ip.dart';
import 'package:finora_app/models/reporte_contable.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../utils/app_logger.dart';

class PDFExportHelperContable {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF5162F6);
  static const PdfColor analysisColor = PdfColor.fromInt(0xFF1565C0);
  static const PdfColor guaranteeColor = PdfColor.fromInt(0xFFE53888);
  static const PdfColor accountingColor = PdfColor.fromInt(0xFF00796B);
  static const PdfColor orangeColor = PdfColor.fromInt(0xFFE65100);

  final ReporteContableData reporteData;
  final NumberFormat currencyFormat;
  final String? selectedReportType;
  final BuildContext context;
  final String? nombreUsuario;

  PDFExportHelperContable(
    this.reporteData,
    this.currencyFormat,
    this.selectedReportType,
    this.context,
    this.nombreUsuario,
  );

  Future<void> exportToPdf() async {
    try {
      final pdfDocument = await _generatePDF();
      final Uint8List pdfBytes = await pdfDocument.save();
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Exportar Reporte Contable',
        fileName:
            'reporte_contable_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
        bytes: pdfBytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (kIsWeb) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Descarga iniciada.')));
      } else if (outputFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reporte exportado correctamente'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Abrir',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(outputFile),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.log('Error al exportar PDF: $e');
    }
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    final userData = Provider.of<UserDataProvider>(context, listen: false);

    final logoColor = userData.imagenes.firstWhereOrNull(
      (img) => img.tipoImagen == 'logoColor',
    );
    final logoUrl =
        logoColor != null
            ? '$baseUrl/imagenes/subidas/${logoColor.rutaImagen}'
            : null;
    final financieraLogo = await _loadNetworkImage(logoUrl);
    final ByteData data = await rootBundle.load('assets/finora.png');
    final finoraLogo = data.buffer.asUint8List();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(15),
        header: (context) => _buildHeader(financieraLogo, finoraLogo),
        build:
            (context) => [
              ...reporteData.listaGrupos
                  .map((grupo) => _buildGrupoDashboard(grupo))
                  .toList(),
              _buildTotalesFinales(),
            ],
      ),
    );
    return pdf;
  }

  pw.Widget _buildGrupoDashboard(ReporteContableGrupo grupo) {
    // Definimos el espacio deseado
    const double horizontalGap = 8.0;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          _buildCardHeader(grupo),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(2.8),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(1.8),
                3: pw.FlexColumnWidth(2.3),
                4: pw.FlexColumnWidth(2.3),
              },
              children: [
                pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.top,
                  children: [
                    // Opción A: Padding solo a la derecha para separar del siguiente
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: horizontalGap),
                      child: _buildClientesCol(grupo),
                    ),
                    
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: horizontalGap),
                      child: _buildInfoCreditoCol(grupo),
                    ),
                    
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: horizontalGap),
                      child: _buildDepositosCol(grupo),
                    ),
                    
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: horizontalGap),
                      child: _buildRecuperacionCol(grupo),
                    ),
                    
                    // El último elemento no necesita margen a la derecha
                    _buildDesgloseContableCol(grupo), 
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- COLUMNA 4: RECUPERACIÓN DE INVERSIÓN (CORREGIDA) ---
// --- COLUMNA 4: RECUPERACIÓN DE INVERSIÓN (LÓGICA IDÉNTICA A SCREEN) ---
  // --- COLUMNA 4: RECUPERACIÓN DE INVERSIÓN (REDISEÑADA) ---
  pw.Widget _buildRecuperacionCol(ReporteContableGrupo grupo) {
    // 1. CÁLCULOS
    final double capitalPendienteReal = max(0, grupo.montoDesembolsado - grupo.saldoGlobal).toDouble();
    final double intSobrDesemb = max(0, grupo.saldoGlobal - grupo.montoDesembolsado).toDouble();
    final double intSobreSol = max(0, grupo.saldoGlobal - grupo.montoSolicitado).toDouble();

    final double pagoTotalAplicado = grupo.pagoficha.sumaDeposito + grupo.pagoficha.favorUtilizado;

    // Filtrar depósitos que no son solo garantía para calcular efectivo real
    final double depositosSinGarantia = grupo.pagoficha.depositos
        .where((d) => d.garantia != 'Si')
        .fold(0.0, (sum, d) => sum + d.deposito);
    
    final double pagoEfectivoPeriodo = depositosSinGarantia + grupo.pagoficha.favorUtilizado;

    final bool huboPagoConGarantia = (pagoTotalAplicado - pagoEfectivoPeriodo).abs() > 0.01;
    final bool esPagoSoloConGarantia = pagoEfectivoPeriodo < 0.01 && pagoTotalAplicado > 0;

    double capitalAplicadoTotal = 0;
    double interesAplicadoTotal = 0;

    if (pagoTotalAplicado > 0) {
      final saldoGlobalAnterior = grupo.saldoGlobal - pagoTotalAplicado;
      final double capitalPendienteAnterior = max(0, grupo.montoDesembolsado - saldoGlobalAnterior).toDouble();

      capitalAplicadoTotal = (capitalPendienteAnterior - capitalPendienteReal).toDouble();
      interesAplicadoTotal = pagoTotalAplicado - capitalAplicadoTotal;
    }

    // Distribución Efectiva (Cash) vs Aplicada
    final double capitalPagadoEfectivo = min(capitalAplicadoTotal, pagoEfectivoPeriodo);
    final double interesPagadoEfectivo = pagoEfectivoPeriodo - capitalPagadoEfectivo;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Recuperación de Inversión', analysisColor),
          pw.SizedBox(height: 6),
          
          // --- PARTE SUPERIOR: DOS COLUMNAS (Capital Pendiente | Interés Acumulado) ---
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Columna Izquierda: Capital Pendiente
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Capital Desemb.', style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600)),
                    pw.Text('Pendiente', style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600)),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      currencyFormat.format(capitalPendienteReal),
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 4),
              // Columna Derecha: Interés Acumulado
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Interés Acumulado', style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600)),
                    pw.Text('(s/ Solicitado)', style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600)),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      currencyFormat.format(intSobreSol),
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: analysisColor),
                    ),
                    pw.Text(
                      '(s. desemb: ${currencyFormat.format(intSobrDesemb)})',
                      style: const pw.TextStyle(fontSize: 4, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 6),
          pw.Divider(height: 1, thickness: 0.5, color: PdfColors.grey300),
          pw.SizedBox(height: 6),

          if (pagoTotalAplicado > 0) ...[
            pw.Text('Aplicación del Pago de este Período', style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
            pw.SizedBox(height: 4),
            
            // --- PARTE MEDIA: CAJAS DE ABONO (Estilo Card) ---
            pw.Row(children: [
              pw.Expanded(child: _buildAnalysisBox(
                'Abono a Capital', 
                capitalPagadoEfectivo, 
                capitalAplicadoTotal, 
                huboPagoConGarantia
              )),
              pw.SizedBox(width: 6), // Más espacio entre cajas
              pw.Expanded(child: _buildAnalysisBox(
                'Abono a Interés', 
                interesPagadoEfectivo, 
                interesAplicadoTotal, 
                huboPagoConGarantia,
                color: interesPagadoEfectivo > 0 ? analysisColor : null // Azul si hay pago
              )),
            ]),
            
            pw.SizedBox(height: 6),
            
            // --- PARTE INFERIOR: NOTA DINÁMICA (Estilo Alerta/Éxito) ---
            _buildPdfAnalysisNote(
              capitalAplicadoTotal, 
              interesAplicadoTotal, 
              pagoTotalAplicado, 
              esPagoSoloConGarantia, 
              huboPagoConGarantia
            ),
          ] else ...[
             // Estado vacío si no hay pagos
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 5),
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Row(
                children: [
                   pw.Container(width: 4, height: 4, decoration: const pw.BoxDecoration(color: PdfColors.grey400, shape: pw.BoxShape.circle)),
                   pw.SizedBox(width: 4),
                   pw.Text("Sin movimientos en este período.", style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey600)),
                ]
              ),
            )
          ]
        ],
      ),
    );
  }

  // --- HELPERS ACTUALIZADOS PARA DISEÑO VISUAL ---

  pw.Widget _buildAnalysisBox(String label, double cashValue, double appliedValue, bool showAppliedValue, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(
            currencyFormat.format(cashValue), 
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: color ?? PdfColors.black)
          ),
          if (showAppliedValue && appliedValue > 0)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text('(Tot: ${currencyFormat.format(appliedValue)})', style: const pw.TextStyle(fontSize: 3.5, color: PdfColors.grey400)),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfAnalysisNote(
    double capital,
    double interes,
    double pagoTotal,
    bool esSoloGarantia,
    bool huboPagoConGarantia,
  ) {
    String message;
    PdfColor bgColor;
    PdfColor iconColor;
    const double epsilon = 0.01;

    // Lógica idéntica al Screen
    if (esSoloGarantia) {
      message = 'El crédito se cubrió con garantía. No representa un ingreso.';
      bgColor = PdfColor.fromInt(0xFFFCE4EC); // Pink 50
      iconColor = guaranteeColor;
    } else if (huboPagoConGarantia) {
      if (capital < epsilon) {
        message = 'El depósito se aplicó a interés; el resto se cubrió con garantía.';
        bgColor = PdfColor.fromInt(0xFFE8F5E9); // Green 50
        iconColor = PdfColors.green;
      } else {
        message = 'El pago en efectivo fue aplicado y se complementó con garantía.';
        bgColor = PdfColor.fromInt(0xFFE3F2FD); // Blue 50
        iconColor = analysisColor;
      }
    } else if (capital < epsilon && pagoTotal > 0) {
      message = 'El capital del crédito ya fue cubierto. Este pago se aplica 100% a interés.';
      bgColor = PdfColor.fromInt(0xFFE8F5E9); // Green 50
      iconColor = PdfColors.green;
    } else if (interes < epsilon && pagoTotal > 0) {
      message = 'Este pago se aplica 100% a capital pendiente.';
      bgColor = PdfColor.fromInt(0xFFE3F2FD); // Blue 50
      iconColor = analysisColor;
    } else {
      message = 'Este pago se dividió para cubrir parte del capital y del interés.';
      bgColor = PdfColor.fromInt(0xFFFFF3E0); // Orange 50
      iconColor = orangeColor;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Icono simulado (Círculo con color)
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 1),
            width: 6,
            height: 6,
            decoration: pw.BoxDecoration(
              color: iconColor,
              shape: pw.BoxShape.circle,
            ),
            
          ),
          pw.SizedBox(width: 5),
          // Texto del mensaje
          pw.Expanded(
            child: pw.Text(
              message,
              style: pw.TextStyle(fontSize: 4.5, color: PdfColors.grey800, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ESPECÍFICOS PARA RECUPERACIÓN ---

  
  // --- COLUMNA 5: DESGLOSE CAPITAL E INTERÉS (CORREGIDA CON REDONDEO) ---
  pw.Widget _buildDesgloseContableCol(ReporteContableGrupo grupo) {
    final double pagoTotal =
        grupo.pagoficha.sumaDeposito + grupo.pagoficha.favorUtilizado;
    final double capSem = grupo.capitalsemanal;
    final double intSem = grupo.interessemanal;
    final double ficha = grupo.montoficha;

    // Distribución Pago Actual (Prioridad Capital)
    final double capActual = min(pagoTotal, capSem);
    final double intActual = max(0, pagoTotal - capActual);

    // Cálculos de Redondeo (Diferencia entre Ficha y suma de componentes)
    final double diffRedondeo = max(0, ficha - (capSem + intSem));
    final double ratioGlobal = ficha > 0 ? (grupo.saldoGlobal / ficha) : 0;

    final double redondeoPagado = diffRedondeo * ratioGlobal;
    final double redondeoTotalOriginal = diffRedondeo * grupo.plazo;
    final double redondeoRestante = max(
      0,
      redondeoTotalOriginal - redondeoPagado,
    );

    // Acumulados Proporcionales
    double capAcumulado = 0;
    if (ficha > 0) capAcumulado = grupo.saldoGlobal * (capSem / ficha);
    final double intAcumulado = max(0, grupo.saldoGlobal - capAcumulado);

    final double capRestante = max(0, grupo.montoSolicitado - capAcumulado);
    final double intRestante = max(0, grupo.interesCredito - intAcumulado);

    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      /* decoration: pw.BoxDecoration(
        border: pw.Border.all(color: accountingColor.shade(0.3)),
        borderRadius: pw.BorderRadius.circular(4),
      ), */
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Desglose Capital e Interés', accountingColor),
          pw.SizedBox(height: 4),
          pw.Text(
            'Distribución Pago Actual',
            style: pw.TextStyle(
              fontSize: 5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildBoxWithBase(
                  'Abono Cap. (Real)',
                  capActual,
                  capSem,
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Expanded(
                child: _buildBoxWithBase(
                  'Abono Int. (Real)',
                  intActual,
                  intSem,
                  color: accountingColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Estado Global (Acumulado)',
            style: pw.TextStyle(
              fontSize: 5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 2),
          // Filas con Redondeo
          _buildCumulativeRow(
            'Cap. Pagado',
            capAcumulado,
            'Int. Pagado',
            intAcumulado,
            redondeoPagado,
          ),
          pw.SizedBox(height: 2),
          _buildCumulativeRow(
            'Cap. Restante',
            capRestante,
            'Int. Restante',
            intRestante,
            redondeoRestante,
            isWarning: true,
          ),

          pw.SizedBox(height: 6),
          // Bloque Deuda Original
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Column(
              children: [
                _buildDeudaDetail('Capital Base:', grupo.montoSolicitado),
                _buildDeudaDetail(
                  'Interés Base:',
                  grupo.interesCredito - redondeoTotalOriginal,
                ),
                if (redondeoTotalOriginal > 0.01)
                  _buildDeudaDetail(
                    'Redondeo Total:',
                    redondeoTotalOriginal,
                    isOrange: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  pw.Widget _buildCumulativeRow(
    String L1,
    double V1,
    String L2,
    double V2,
    double redondeo, {
    bool isWarning = false,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(child: _buildMiniStatLabel(L1, V1, isWarning: isWarning)),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildMiniStatLabel(
                L2,
                V2,
                isWarning: isWarning,
                color: accountingColor,
              ),
              if (redondeo > 0.01)
                pw.Text(
                  '+ Redondeo: ${currencyFormat.format(redondeo)}',
                  style: pw.TextStyle(
                    fontSize: 4.5,
                    color: orangeColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMiniStatLabel(
    String label,
    double val, {
    bool isWarning = false,
    PdfColor? color,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey500),
        ),
        pw.Text(
          currencyFormat.format(val),
          style: pw.TextStyle(
            fontSize: 6,
            fontWeight: pw.FontWeight.bold,
            color: isWarning ? orangeColor : (color ?? PdfColors.black),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDeudaDetail(
    String label,
    double val, {
    bool isOrange = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 5,
            color: isOrange ? orangeColor : PdfColors.grey700,
          ),
        ),
        pw.Text(
          currencyFormat.format(val),
          style: pw.TextStyle(
            fontSize: 5,
            fontWeight: pw.FontWeight.bold,
            color: isOrange ? orangeColor : PdfColors.black,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMiniStatBox(String label, double val) => pw.Container(
    padding: const pw.EdgeInsets.all(3),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey200),
      borderRadius: pw.BorderRadius.circular(2),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600),
        ),
        pw.Text(
          currencyFormat.format(val),
          style: pw.TextStyle(
            fontSize: 6,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    ),
  );

  pw.Widget _buildBoxWithBase(
    String label,
    double val,
    double base, {
    PdfColor? color,
  }) => pw.Container(
    padding: const pw.EdgeInsets.all(3),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey50,
      border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
      borderRadius: pw.BorderRadius.circular(2),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600),
        ),
        pw.Text(
          currencyFormat.format(val),
          style: pw.TextStyle(
            fontSize: 6,
            fontWeight: pw.FontWeight.bold,
            color: color ?? PdfColors.black,
          ),
        ),
        pw.Divider(height: 3, thickness: 0.3),
        pw.Text(
          'Base: ${currencyFormat.format(base)}',
          style: const pw.TextStyle(fontSize: 4, color: PdfColors.grey500),
        ),
      ],
    ),
  );

  // --- EL RESTO DE MÉTODOS (Clientes, Info Crédito, Header, etc.) PERMANECEN IGUAL ---

  // --- COLUMNA 1: CLIENTES (CORREGIDA) ---
  pw.Widget _buildClientesCol(ReporteContableGrupo grupo) {
    // Cálculos de totales del grupo
    double totalCap = grupo.clientes.fold(0, (sum, c) => sum + c.periodoCapital);
    double totalInt = grupo.clientes.fold(0, (sum, c) => sum + c.periodoInteres);
    double totalGen = grupo.clientes.fold(0, (sum, c) => sum + c.capitalMasInteres);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Clientes (${grupo.clientes.length})', primaryColor),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.5), // Nombre
            1: pw.FlexColumnWidth(1.2), // Capital
            2: pw.FlexColumnWidth(1.2), // Interés
            3: pw.FlexColumnWidth(1.4), // Total
          },
          children: [
            // Cabecera Tabla
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildCell('Nombre', isHeader: true),
                _buildCell('Cap', isHeader: true, alignRight: true),
                _buildCell('Int', isHeader: true, alignRight: true),
                _buildCell('Total', isHeader: true, alignRight: true),
              ],
            ),
            // Filas de Clientes
            ...grupo.clientes.map((c) => pw.TableRow(
              children: [
                _buildCell(c.nombreCompleto),
                _buildCell(currencyFormat.format(c.periodoCapital), alignRight: true),
                _buildCell(currencyFormat.format(c.periodoInteres), alignRight: true),
                _buildCell(currencyFormat.format(c.capitalMasInteres), alignRight: true),
              ],
            )),
            // Fila de Totales
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEDEFFE)), // Color suave primario
              children: [
                _buildCell('Totales', isHeader: true),
                _buildCell(currencyFormat.format(totalCap), isHeader: true, alignRight: true),
                _buildCell(currencyFormat.format(totalInt), isHeader: true, alignRight: true),
                _buildCell(currencyFormat.format(totalGen), isHeader: true, alignRight: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- COLUMNA 2: INFO CRÉDITO (CORREGIDA - TODOS LOS CAMPOS) ---
  pw.Widget _buildInfoCreditoCol(ReporteContableGrupo grupo) {
    final double interesSinRedondear = grupo.interessemanal * grupo.plazo;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información del Crédito', primaryColor),
          pw.SizedBox(height: 6),

          // --- BLOQUE PRINCIPAL EN GRID (2 COLUMNAS) ---
          // Esto imita la alineación visual de la web
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // COLUMNA IZQUIERDA
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildGridStatItem('Garantía', grupo.garantia, isHighlighted: true),
                    pw.SizedBox(height: 4),
                    _buildGridStatItem('Monto Solicitado', currencyFormat.format(grupo.montoSolicitado)),
                    pw.SizedBox(height: 4),
                    _buildGridStatItem('Interés Total', currencyFormat.format(interesSinRedondear)),
                  ],
                ),
              ),
              pw.SizedBox(width: 4),
              // COLUMNA DERECHA
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildGridStatItem('Tasa', '${grupo.tazaInteres}%', isHighlighted: true),
                    pw.SizedBox(height: 4),
                    _buildGridStatItem('Monto Desembolsado', currencyFormat.format(grupo.montoDesembolsado)),
                    pw.SizedBox(height: 4),
                    _buildGridStatItem('Monto a Recuperar', currencyFormat.format(grupo.montoARecuperar)),
                  ],
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 4),
          pw.Divider(height: 6, thickness: 0.5, color: PdfColors.grey300),
          
          // --- BLOQUE DE PAGOS SEMANALES ---
          // Aquí mantenemos el formato de fila compacta para ahorrar espacio vertical
          _buildRowDetail('Cap. Semanal', grupo.capitalsemanal, useFormat: true),
          _buildRowDetail('Int. Semanal', grupo.interessemanal, useFormat: true),
          pw.SizedBox(height: 2),
          // Ficha destacada
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(2)
            ),
            child: _buildRowDetail('Monto Ficha', grupo.montoficha, useFormat: true, isBold: true, color: primaryColor),
          ),
          
          pw.Divider(height: 8, thickness: 0.5, color: PdfColors.grey300),

          // --- BLOQUE DE MORATORIOS ---
          pw.Row(
            children: [
              pw.Expanded(child: _buildMiniStatLabel('Mor. Generados', grupo.moratorios.moratoriosAPagar, color: PdfColors.red700)),
              pw.SizedBox(width: 4),
              pw.Expanded(child: _buildMiniStatLabel('Mor. Pagados', grupo.pagoficha.sumaMoratorio, color: PdfColors.green700)),
            ],
          ),
        ],
      ),
    );
  }

  // --- HELPER NUEVO PARA EL ESTILO "GRID" ---
  pw.Widget _buildGridStatItem(String label, String value, {bool isHighlighted = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isHighlighted ? 7 : 6, // Un poco más grande si es Tasa/Garantía
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  // --- COLUMNA 3: DEPÓSITOS (CORREGIDA - DETALLE COMPLETO) ---
  pw.Widget _buildDepositosCol(ReporteContableGrupo grupo) {
    final pagoficha = grupo.pagoficha;
    
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header con Fecha Programada
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Depósitos', primaryColor),
              pw.Text('Prog: ${_formatDateSafe(pagoficha.fechasPago)}', style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 4),

          // Lista de Depósitos
          if (pagoficha.depositos.isEmpty && pagoficha.favorUtilizado == 0)
            pw.Container(
              padding: const pw.EdgeInsets.all(5),
              alignment: pw.Alignment.center,
              child: pw.Text('Sin depósitos registrados.', style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey500)),
            )
          else ...[
            ...pagoficha.depositos.map((d) => _buildPdfDepositCard(d)),
            if (pagoficha.favorUtilizado > 0)
               _buildFavorUtilizadoBox(pagoficha.favorUtilizado),
          ],

          // Saldo a Favor Generado (Si existe)
          if (pagoficha.saldofavor > 0)
            _buildSaldoFavorGeneradoBox(pagoficha),

          pw.SizedBox(height: 4),

          // Totales de la Ficha
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEDEFFE)),
            child: _buildRowDetail('Total depósitos:', pagoficha.sumaDeposito + pagoficha.favorUtilizado, useFormat: true, isBold: true, color: primaryColor),
          ),
          pw.SizedBox(height: 2),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFF3E0)),
            child: _buildRowDetail('Restante ficha:', grupo.restanteFicha, useFormat: true, isBold: true, color: orangeColor),
          ),

          pw.SizedBox(height: 6),

          // Resumen Global (Parte inferior)
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Resumen Global', style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                pw.SizedBox(height: 3),
                _buildRowDetail('Saldo Global', grupo.saldoGlobal, useFormat: true),
                _buildRowDetail('Restante Global', grupo.restanteGlobal, useFormat: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCardHeader(ReporteContableGrupo grupo) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: const pw.BoxDecoration(
      color: PdfColors.grey50,
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '${grupo.grupos.toUpperCase()} (Folio: ${grupo.folio})',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
            fontSize: 8,
          ),
        ),
        pw.Row(
          children: [
            _buildHeaderStat('Pago', grupo.tipopago),
            _buildHeaderStat('Plazo', grupo.plazo.toString()),
            _buildHeaderStat('Periodo', grupo.pagoPeriodo.toString()),
          ],
        ),
      ],
    ),
  );

  pw.Widget _buildHeaderStat(String l, String v) => pw.Padding(
    padding: const pw.EdgeInsets.only(left: 8),
    child: pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(fontSize: 6),
        children: [
          pw.TextSpan(
            text: '$l: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(text: v),
        ],
      ),
    ),
  );

  pw.Widget _buildSectionTitle(String title, PdfColor color) => pw.Row(
    children: [
      pw.Container(width: 2, height: 7, color: color),
      pw.SizedBox(width: 3),
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 6,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );

  pw.Widget _buildRowDetail(
    String label,
    dynamic val, {
    bool isBold = false,
    bool useFormat = false,
    PdfColor? color,
  }) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        label,
        style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey700),
      ),
      pw.Text(
        useFormat ? currencyFormat.format(val) : val.toString(),
        style: pw.TextStyle(
          fontSize: 5.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    ],
  );

  pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool alignRight = false,
  }) => pw.Container(
    padding: const pw.EdgeInsets.all(2),
    alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 5.5,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

 pw.Widget _buildHeader(Uint8List? financieraLogo, Uint8List finoraLogo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // --- LOGOS (Copiado exacto del General) ---
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (financieraLogo != null)
              pw.Image(
                pw.MemoryImage(financieraLogo),
                width: 120,
                height: 40,
                fit: pw.BoxFit.contain,
              ),
            pw.Image(
              pw.MemoryImage(finoraLogo),
              width: 120,
              height: 40,
              fit: pw.BoxFit.contain,
            ),
          ],
        ),
        
        pw.SizedBox(height: 10),
        
        // --- TÍTULO ---
        pw.Text(
          selectedReportType ?? '',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#5162F6'),
          ),
        ),

        pw.SizedBox(height: 10),

        // --- ASESOR (Copiado exacto del General) ---
        if (nombreUsuario != null &&
            nombreUsuario!.isNotEmpty &&
            nombreUsuario != 'Todos los usuarios')
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              'Asesor: $nombreUsuario',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        
        pw.SizedBox(height: 5), // Espacio ajustado según tu código General

        // --- FECHAS (Período y Generado) ---
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Período: ${reporteData.fechaSemana}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        
        pw.SizedBox(height: 10),
      ],
    );
  }

  // --- TOTALES FINALES (Lógica idéntica a Screen) ---
  // --- TOTALES FINALES CON SUB-DATOS (TIPO TOOLTIP) ---
  // --- TOTALES FINALES COMPLETOS (Lógica Desktop Screen) ---
  pw.Widget _buildTotalesFinales() {
    final groups = reporteData.listaGrupos;

    // 1. CÁLCULOS IDEALES
    final double totalCapIdeal = groups.fold(0.0, (sum, g) => sum + g.capitalsemanal);
    final double totalIntIdeal = groups.fold(0.0, (sum, g) => sum + g.interessemanal);
    final double totalFichaIdeal = groups.fold(0.0, (sum, g) => sum + g.montoficha);

    // 2. CÁLCULOS REALES Y DE INVERSIÓN (Lógica exacta de tu Screen)
    final double totalPagoEf = groups.fold(0.0, (sum, g) {
      final dEf = g.pagoficha.depositos.where((d) => d.garantia != 'Si').fold(0.0, (s, d) => s + d.deposito);
      return sum + dEf + g.pagoficha.favorUtilizado;
    });
    
    final double totalPagoConGarantia = groups.fold(0.0, (sum, g) => sum + g.pagoficha.sumaDeposito + g.pagoficha.favorUtilizado);

    double tCapAmortEf = 0; double tIntAmortEf = 0;
    double tCapAmortTot = 0; double tIntAmortTot = 0;
    double tCapRecupEf = 0; double tIntRecupEf = 0;
    double tCapRecupTot = 0; double tIntRecupTot = 0;

    for (var g in groups) {
      final ef = g.pagoficha.depositos.where((d) => d.garantia != 'Si').fold(0.0, (s, d) => s + d.deposito) + g.pagoficha.favorUtilizado;
      final tot = g.pagoficha.sumaDeposito + g.pagoficha.favorUtilizado;

      if (tot > 0) {
        // Lógica Ficha (Gaviotas: Prioridad Capital)
        final cAmortEf = min(ef, g.capitalsemanal);
        tCapAmortEf += cAmortEf;
        tIntAmortEf += (ef - cAmortEf);

        final cAmortTot = min(tot, g.capitalsemanal);
        tCapAmortTot += cAmortTot;
        tIntAmortTot += (tot - cAmortTot);

        // Lógica Inversión (Desembolso Real)
        final saldoAnt = g.saldoGlobal - tot;
        final cPendAnt = max(0.0, g.montoDesembolsado - saldoAnt);
        final cPendAct = max(0.0, g.montoDesembolsado - g.saldoGlobal);
        
        final rCapTot = (cPendAnt - cPendAct).toDouble();
        tCapRecupTot += rCapTot;
        tIntRecupTot += (tot - rCapTot);

        final rCapEf = min(ef, rCapTot);
        tCapRecupEf += rCapEf;
        tIntRecupEf += (ef - rCapEf);
      }
    }

    final double totalSaldoDisp = groups.fold(0.0, (sum, g) => sum + g.pagoficha.saldoDisponible);
    final double totalMorPagados = groups.fold(0.0, (sum, g) => sum + g.pagoficha.sumaMoratorio);
    
    // Totales Finales
    final double nuevoTotalBruto = totalPagoEf + totalSaldoDisp + totalMorPagados;
    final double diferencia = totalFichaIdeal - totalPagoEf;

    // 3. UI ADAPTADA A PDF (Horizontal)
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Título Vertical
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.SizedBox(height: 8),
              pw.Text('TOTALES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: primaryColor)),
            ],
          ),
          pw.SizedBox(width: 6),
          pw.Container(height: 30, width: 1, color: PdfColors.grey300),
          pw.SizedBox(width: 6),

          // Contenido Horizontal Scrollable simulado con Expanded
          pw.Expanded(
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. Ideales
                _buildSimpleTotal('Cap. Ideal', totalCapIdeal),
                _buildSimpleTotal('Int. Ideal', totalIntIdeal),
                _buildSimpleTotal('Monto Ficha', totalFichaIdeal, isBold: true),
                
                _buildVerticalDivider(),

                // 2. Pago Fichas (+ Garantía Tooltip)
                _buildComplexTotalItem(
                  'Pago Fichas', 
                  totalPagoEf,
                  subLines: [
                    'c/ Gar: ${currencyFormat.format(totalPagoConGarantia)}'
                  ],
                  isBold: true,
                  color: PdfColors.green700
                ),

                // 3. Capital Recuperado (Complejo)
                _buildComplexTotalItem(
                  'Cap. Rec. (Período)', 
                  tCapAmortEf,
                  subLines: [
                    'c/ Gar: ${currencyFormat.format(tCapAmortTot)}',
                    'Inv. Real: ${currencyFormat.format(tCapRecupEf)}',
                    'Inv. Gar: ${currencyFormat.format(tCapRecupTot)}',
                  ]
                ),

                // 4. Interés Recuperado (Complejo)
                _buildComplexTotalItem(
                  'Int. Rec. (Período)', 
                  tIntAmortEf,
                  subLines: [
                    'c/ Gar: ${currencyFormat.format(tIntAmortTot)}',
                    'Inv. Real: ${currencyFormat.format(tIntRecupEf)}',
                    'Inv. Gar: ${currencyFormat.format(tIntRecupTot)}',
                  ]
                ),

                _buildVerticalDivider(),

                // 5. Contables
                _buildSimpleTotal('S. Favor', totalSaldoDisp, color: PdfColors.teal700),
                _buildSimpleTotal('Mor. Pag.', totalMorPagados, color: PdfColors.orange800),

                _buildVerticalDivider(),

                // 6. Totales Finales
                _buildSimpleTotal('Total Ideal', totalFichaIdeal, color: primaryColor, isBold: true),
                
                _buildSimpleTotal(
                  'Diferencia', 
                  diferencia, 
                  color: diferencia > 0.01 ? PdfColors.red700 : PdfColors.green700, 
                  isBold: true
                ),

                // 7. Total Bruto (Caja Azul)
                _buildTotalBox('Total Bruto', nuevoTotalBruto),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS PARA LA TARJETA DE TOTALES ---

  pw.Widget _buildVerticalDivider() => pw.Container(
    height: 25, 
    width: 0.5, 
    color: PdfColors.grey300, 
    margin: const pw.EdgeInsets.symmetric(horizontal: 4)
  );

  // Item simple (Una sola línea de valor)
  pw.Widget _buildSimpleTotal(String label, double val, {bool isBold = false, PdfColor? color}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600)),
        pw.Text(
          currencyFormat.format(val),
          style: pw.TextStyle(
            fontSize: 6,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  // Item complejo (Simula el Tooltip con líneas pequeñas abajo)
  pw.Widget _buildComplexTotalItem(String label, double val, {required List<String> subLines, bool isBold = false, PdfColor? color}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600)),
        pw.Text(
          currencyFormat.format(val),
          style: pw.TextStyle(
            fontSize: 6,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
        // Renderizamos las líneas del "Tooltip"
        ...subLines.map((line) => pw.Text(
          line,
          style: const pw.TextStyle(fontSize: 3.5, color: PdfColors.grey500),
        )),
      ],
    );
  }

  // Caja destacada para el Total Bruto
  pw.Widget _buildTotalBox(String label, double val) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.white)),
          pw.Text(
            currencyFormat.format(val),
            style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _loadNetworkImage(String? url) async {
    if (url == null) return null;
    try {
      final r = await http.get(Uri.parse(url));
      return r.statusCode == 200 ? r.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  String _formatDateSafe(String d) {
    try {
      return DateFormat('dd/MM/yy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  // --- HELPERS AUXILIARES PARA DEPÓSITOS E INFO ---

  pw.Widget _buildSimpleInfo(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 4.5, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildPdfDepositCard(Deposito d) {
    final bool isGarantia = d.garantia == "Si";
    final bool isGlobal = d.esSaldoGlobal == "Si";
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            color: PdfColors.grey100,
            child: pw.Text('Fecha: ${_formatDateSafe(d.fechaDeposito)}', style: const pw.TextStyle(fontSize: 4.5), textAlign: pw.TextAlign.center),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStatLabel('Depósito', d.deposito),
                    _buildMiniStatLabel('Moratorio', d.pagoMoratorio),
                  ],
                ),
                if (isGarantia || isGlobal)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Row(
                      children: [
                        if (isGarantia) _buildTag('Garantía', guaranteeColor),
                        if (isGarantia && isGlobal) pw.SizedBox(width: 2),
                        if (isGlobal) _buildTag('Abono Global', PdfColors.teal),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTag(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(2)),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 4, color: PdfColors.white)),
    );
  }

  pw.Widget _buildFavorUtilizadoBox(double amount) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3),
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green700, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Abono c/ S. Favor', style: pw.TextStyle(fontSize: 4.5, color: PdfColors.green900)),
          pw.Text(currencyFormat.format(amount), style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
        ],
      ),
    );
  }

  pw.Widget _buildSaldoFavorGeneradoBox(Pagoficha p) {
    String label = 'S. Favor Generado';
    if(p.utilizadoPago == 'Si') label = 'S. Favor (Utilizado)';
    else if(p.saldoUtilizado > 0) label = 'S. Favor Disp.';

    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        color: PdfColors.green100,
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 4.5, color: PdfColors.green900, fontWeight: pw.FontWeight.bold)),
          pw.Text(currencyFormat.format(p.saldofavor), style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
        ],
      ),
    );
  }
}
