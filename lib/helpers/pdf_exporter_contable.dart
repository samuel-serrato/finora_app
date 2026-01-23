// lib/helpers/pdf_exporter_contable.dart (VERSIÓN FINAL CON CORRECCIONES)

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
  static const PdfColor abonoGlobalColor = PdfColor.fromInt(0xFF008080);
  static const PdfColor favorUsedColor = PdfColor.fromInt(0xFF28a745);
  static const PdfColor saldoFavorBgColor = PdfColor.fromInt(0xFFe3f2fd);
  static const PdfColor saldoFavorFgColor = PdfColor.fromInt(0xFF0d47a1);
  static const PdfColor restanteFichaColor = PdfColor.fromInt(0xFFe9661d);
  static const PdfColor restanteFichaBgColor = PdfColor.fromInt(0xFFfff3e0);
  static const PdfColor greenColor = PdfColor.fromInt(0xFF4CAF50);
  static const PdfColor orangeColor = PdfColor.fromInt(0xFFFF9800);

  static const PdfColor softPrimaryBg = PdfColor.fromInt(0xFFE8EAF6);
  static const PdfColor softGuaranteeBg = PdfColor.fromInt(0xFFFCE4EC);
  static const PdfColor softGreenBg = PdfColor.fromInt(0xFFE8F5E9);
  static const PdfColor softOrangeBg = PdfColor.fromInt(0xFFFFF3E0);

  final ReporteContableData reporteData;
  final NumberFormat currencyFormat;
  final String? selectedReportType;
  final BuildContext context;

  PDFExportHelperContable(
    this.reporteData,
    this.currencyFormat,
    this.selectedReportType,
    this.context,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La descarga del reporte ha comenzado.'),
            backgroundColor: Colors.green,
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final logoColor =
        userData.imagenes.firstWhereOrNull((img) => img.tipoImagen == 'logoColor');
    final logoUrl =
        logoColor != null ? '$baseUrl/imagenes/subidas/${logoColor.rutaImagen}' : null;
    final financieraLogo = await _loadNetworkImage(logoUrl);

    final ByteData data = await rootBundle.load('assets/finora.png');
    final finoraLogo = data.buffer.asUint8List();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),
        build: (context) => [
          _buildHeader(
            selectedReportType: selectedReportType,
            financieraLogo: financieraLogo,
            finoraLogo: finoraLogo,
          ),
          pw.SizedBox(height: 8),
          pw.ListView.builder(
            itemCount: reporteData.listaGrupos.length,
            itemBuilder: (context, index) {
              final grupo = reporteData.listaGrupos[index];
              return _buildGrupoCard(grupo);
            },
          ),
          pw.SizedBox(height: 10),
          _buildTotalesCard(),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ),
      ),
    );

    return pdf;
  }

  pw.Widget _buildGrupoCard(ReporteContableGrupo grupo) {
    return pw.Container(
      child: pw.Column(children: [pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildGrupoHeader(grupo),
                pw.Divider(color: PdfColors.grey400, height: 10, thickness: 0.5),
                pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3.0), // Clientes (más ancho)
                    1: pw.FlexColumnWidth(2.2), // Info Crédito
                    2: pw.FlexColumnWidth(2.2), // Depósitos
                    3: pw.FlexColumnWidth(2.2), // Análisis
                  },
                  children: [
                    pw.TableRow(
                      verticalAlignment: pw.TableCellVerticalAlignment.top,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 6),
                          child: _buildClientesTable(grupo),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 6),
                          child: _buildFinancialInfoSection(grupo),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 6),
                          child: _buildDepositosSection(
                            grupo.pagoficha,
                            grupo.restanteFicha,
                            grupo,
                          ),
                        ),
                        _buildCapitalRecoverySectionPdf(grupo),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      )],),
    );
  }

  // =======================================================================
  // === INICIO DEL CAMBIO: ESTA ES LA FUNCIÓN PRINCIPAL QUE SE AJUSTÓ ===
  // =======================================================================

  pw.Widget _buildCapitalRecoverySectionPdf(ReporteContableGrupo grupo) {
    // 1. REPLICAR TODAS LAS VARIABLES DE LA LÓGICA DE UI
    final double capitalPendienteReal =
        max(0, grupo.montoDesembolsado - grupo.saldoGlobal).toDouble();
    final double interesSobreDesembolso =
        max(0, grupo.saldoGlobal - grupo.montoDesembolsado).toDouble();

    // === SE AÑADE EL CÁLCULO QUE FALTABA ===
    final double interesSobreSolicitado =
        max(0, grupo.saldoGlobal - grupo.montoSolicitado).toDouble();

    final double pagoTotalAplicado =
        grupo.pagoficha.sumaDeposito + grupo.pagoficha.favorUtilizado;

    final double depositosSinGarantia = grupo.pagoficha.depositos
        .where((d) => d.garantia != 'Si')
        .fold(0.0, (sum, d) => sum + d.deposito);
    final double pagoEfectivoPeriodo =
        depositosSinGarantia + grupo.pagoficha.favorUtilizado;

    final bool huboPagoConGarantia =
        (pagoTotalAplicado - pagoEfectivoPeriodo).abs() > 0.01;
    final bool esPagoSoloConGarantia =
        pagoEfectivoPeriodo < 0.01 && pagoTotalAplicado > 0;

    double capitalAplicadoTotal = 0;
    double interesAplicadoTotal = 0;

    if (pagoTotalAplicado > 0) {
      final saldoGlobalAnterior = grupo.saldoGlobal - pagoTotalAplicado;
      final num capitalPendienteAnterior =
          max(0, grupo.montoDesembolsado - saldoGlobalAnterior);

      capitalAplicadoTotal =
          (capitalPendienteAnterior - capitalPendienteReal).toDouble();
      interesAplicadoTotal = pagoTotalAplicado - capitalAplicadoTotal;
    }

    final double capitalPagadoEfectivo = min(
      capitalAplicadoTotal,
      pagoEfectivoPeriodo,
    );
    final double interesPagadoEfectivo =
        pagoEfectivoPeriodo - capitalPagadoEfectivo;


    // 2. CONSTRUIR EL WIDGET CON LA NUEVA LÓGICA
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Análisis de Recuperación',
            style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
                color: analysisColor)),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSimpleFinancialRow('Cap. Pendiente (Real)', capitalPendienteReal, fontSize: 6),
              pw.SizedBox(height: 4),
              
              // === SE REEMPLAZA EL WIDGET SIMPLE POR UNO COMPUESTO ===
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSimpleFinancialRow('Int. Acumulado (s/ Solicitado)', interesSobreSolicitado, fontSize: 6),
                   pw.Align(
                    alignment: pw.Alignment.centerRight,
                     child: pw.Text(
                      '(s. desembolso: ${currencyFormat.format(interesSobreDesembolso)})',
                      style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700),
                    ),
                   ),
                ]
              ),

              if (pagoTotalAplicado > 0) ...[
                pw.Divider(height: 8, color: PdfColors.grey300),
                pw.Text('Aplicación del Pago del Período',
                    style: pw.TextStyle(
                        fontSize: 5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800)),
                pw.SizedBox(height: 4),
                _buildPdfAnalysisItem(
                  label: 'Abono a Capital',
                  cashValue: capitalPagadoEfectivo,
                  appliedValue: capitalAplicadoTotal,
                  showAppliedValue: huboPagoConGarantia,
                ),
                pw.SizedBox(height: 4),
                _buildPdfAnalysisItem(
                  label: 'Abono a Interés',
                  cashValue: interesPagadoEfectivo,
                  appliedValue: interesAplicadoTotal,
                  showAppliedValue: huboPagoConGarantia,
                ),
                pw.SizedBox(height: 5),
                _buildAnalysisNotePdf(
                  capitalAplicadoTotal,
                  interesAplicadoTotal,
                  pagoTotalAplicado,
                  esPagoSoloConGarantia,
                  huboPagoConGarantia,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // === FIN DEL CAMBIO: El resto del código permanece igual ===
  // =====================================================================

  pw.Widget _buildPdfAnalysisItem({
    required String label,
    required double cashValue,
    required double appliedValue,
    required bool showAppliedValue,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey600)),
        pw.SizedBox(height: 1),
        pw.Text(
          currencyFormat.format(cashValue),
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: primaryColor),
        ),
        if (showAppliedValue && appliedValue > 0.01)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              '(Cubierto: ${currencyFormat.format(appliedValue)})',
              style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildAnalysisNotePdf(
    double capital,
    double interes,
    double pagoTotal,
    bool esSoloGarantia,
    bool huboPagoConGarantia,
  ) {
    String message;
    PdfColor bgColor;
    PdfColor fgColor;

    const double epsilon = 0.01;

    if (esSoloGarantia) {
      message = 'Cubierto 100% con garantía. Sin ingreso en período.';
      bgColor = softGuaranteeBg;
      fgColor = guaranteeColor.shade(0.9);
    } else if (huboPagoConGarantia) {
      if (capital < epsilon) {
        message = 'Depósito aplicado a interés; resto cubierto con garantía.';
        bgColor = softGreenBg;
        fgColor = greenColor.shade(0.9);
      } else {
        message = 'Pago en efectivo complementado con garantía.';
        bgColor = softPrimaryBg;
        fgColor = primaryColor.shade(0.9);
      }
    } else if (capital < epsilon && pagoTotal > 0) {
      message = 'Capital cubierto. Pago 100% a interés.';
      bgColor = softGreenBg;
      fgColor = greenColor.shade(0.9);
    } else if (interes < epsilon && pagoTotal > 0) {
      message = 'Pago 100% a capital pendiente.';
      bgColor = softPrimaryBg;
      fgColor = primaryColor.shade(0.9);
    } else {
      message = 'Pago dividido para cubrir capital e interés.';
      bgColor = softOrangeBg;
      fgColor = orangeColor.shade(0.9);
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Text(
        message,
        style: pw.TextStyle(fontSize: 5, color: fgColor, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildDepositosSection(
      Pagoficha pagoficha, double restanteFicha, ReporteContableGrupo grupo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Depósitos',
                style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor)),
            pw.Text('Programado: ${_formatDateSafe(pagoficha.fechasPago)}',
                style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey600)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Column(
            children: (pagoficha.depositos.isEmpty &&
                    pagoficha.favorUtilizado == 0)
                ? [
                    pw.Container(
                        height: 30,
                        alignment: pw.Alignment.center,
                        child: pw.Text('Sin depósitos',
                            style: pw.TextStyle(
                                color: PdfColors.grey, fontSize: 6)))
                  ]
                : [
                    ...pagoficha.depositos
                        .map((deposito) =>
                            _buildStandardDepositCardPdf(deposito, pagoficha))
                        .toList(),
                    if (pagoficha.favorUtilizado > 0)
                      _buildFavorUtilizadoCardPdf(pagoficha.favorUtilizado),
                  ]),
        if (pagoficha.saldofavor > 0)
          _buildSaldoFavorSummaryCardPdf(pagoficha),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 5),
          decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFedeffe),
              borderRadius: pw.BorderRadius.circular(2)),
          child: _buildSummaryRow('Total depósitos:', pagoficha.sumaDeposito,
              color: primaryColor, fontSize: 6),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 5),
          decoration: pw.BoxDecoration(
              color: restanteFichaBgColor,
              borderRadius: pw.BorderRadius.circular(2)),
          child: _buildSummaryRow('Restante ficha:', restanteFicha,
              color: restanteFichaColor, fontSize: 6),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(2),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Resumen Global',
                  style: pw.TextStyle(
                      fontSize: 5,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
              pw.SizedBox(height: 3),
              _buildSimpleFinancialRow('Saldo Global', grupo.saldoGlobal, fontSize: 6),
              pw.SizedBox(height: 3),
              _buildSimpleFinancialRow('Restante Global', grupo.restanteGlobal, fontSize: 6),
            ],
          ),
        )
      ],
    );
  }

  pw.Widget _buildStandardDepositCardPdf(
    Deposito deposito, Pagoficha pagoficha) {
    final isGarantia = deposito.garantia == "Si";
    final isSaldoGlobal = deposito.esSaldoGlobal == "Si";

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          borderRadius: pw.BorderRadius.circular(2)),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF5F5F5),
                borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(1.5),
                    topRight: pw.Radius.circular(1.5))),
            child: pw.Text(
                'Fecha: ${_formatDateSafe(deposito.fechaDeposito)}',
                style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                        child: _buildDepositoDetailPDF('Depósito',
                            deposito.deposito)),
                    pw.SizedBox(width: 3),
                    pw.Expanded(
                        child: _buildDepositoDetailPDF(
                            'Moratorio', deposito.pagoMoratorio)),
                  ],
                ),
                if (isGarantia || isSaldoGlobal)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Row(
                      children: [
                        if (isGarantia)
                          _buildTagPdf('Garantía', guaranteeColor),
                        if (isGarantia && isSaldoGlobal)
                          pw.SizedBox(width: 2),
                        if (isSaldoGlobal)
                          _buildTagPdf('Abono Global', abonoGlobalColor),
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

  pw.Widget _buildSaldoFavorSummaryCardPdf(Pagoficha pagoficha) {
     String title;
    String primaryText;
    String? secondaryText;
    pw.TextDecoration? decoration;

    if (pagoficha.utilizadoPago == 'Si') {
      title = 'S. Favor (Utilizado)';
      primaryText = currencyFormat.format(pagoficha.saldofavor);
      secondaryText = 'Usado en otro pago.';
      decoration = pw.TextDecoration.lineThrough;
    } else if (pagoficha.saldoUtilizado > 0) {
      title = 'S. Favor Disponible';
      primaryText = currencyFormat.format(pagoficha.saldoDisponible);
      secondaryText =
          'de ${currencyFormat.format(pagoficha.saldofavor)} total';
    } else {
      title = 'S. Favor Generado';
      primaryText = currencyFormat.format(pagoficha.saldofavor);
      secondaryText = 'disponible';
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3, top: 3),
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: saldoFavorBgColor,
        borderRadius: pw.BorderRadius.circular(2),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFbbdefb), width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                    color: saldoFavorFgColor,
                  ),
                ),
                if (secondaryText != null)
                  pw.Text(
                    secondaryText,
                    style: const pw.TextStyle(
                      fontSize: 5,
                      color: PdfColors.grey600,
                    ),
                  ),
              ],
            ),
          ),
          pw.Text(
            primaryText,
            style: pw.TextStyle(
              fontSize: 6,
              fontWeight: pw.FontWeight.bold,
              color: saldoFavorFgColor,
              decoration: decoration,
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _loadNetworkImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.log('Error cargando imagen desde URL: $e');
      }
    }
    return null;
  }

  pw.Widget _buildHeader({
    required String? selectedReportType,
    required Uint8List? financieraLogo,
    required Uint8List finoraLogo,
  }) {
     return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (financieraLogo != null)
              pw.Image(
                pw.MemoryImage(financieraLogo),
                width: 120,
                height: 40,
                fit: pw.BoxFit.contain,
              )
            else
              pw.Container(),
            pw.Image(
              pw.MemoryImage(finoraLogo),
              width: 120,
              height: 40,
              fit: pw.BoxFit.contain,
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          selectedReportType ?? '',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Período: ${reporteData.fechaSemana}',
                style: const pw.TextStyle(fontSize: 8)),
            pw.Text(
                'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildTagPdf(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
      decoration:
          pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(2)),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 5, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildFavorUtilizadoCardPdf(double favorUtilizado) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: favorUsedColor, width: 0.5),
          borderRadius: pw.BorderRadius.circular(2)),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            decoration: pw.BoxDecoration(
                color: favorUsedColor,
                borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(1.5),
                    topRight: pw.Radius.circular(1.5))),
            child: pw.Text('Abono con Saldo a Favor',
                style: pw.TextStyle(
                    fontSize: 5,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Monto utilizado:',
                    style: const pw.TextStyle(fontSize: 6)),
                pw.Text(currencyFormat.format(favorUtilizado),
                    style:
                        pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDepositoDetailPDF(String label, double value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
        pw.Text(currencyFormat.format(value),
            style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildTotalesCard() {
    // === CÁLCULOS SIN GARANTÍA (LOS QUE SE MUESTRAN PRINCIPALMENTE) ===
    final double totalPagofichaSinGarantia = reporteData.listaGrupos.fold(0.0, (sum, g) {
      final depositosSinGarantia = g.pagoficha.depositos
          .where((d) => d.garantia != 'Si')
          .fold(0.0, (depSum, d) => depSum + d.deposito);
      return sum + depositosSinGarantia + g.pagoficha.favorUtilizado;
    });

    double totalCapitalRecaudadoSinGarantia = 0;
    double totalInteresRecaudadoSinGarantia = 0;

    for (var g in reporteData.listaGrupos) {
      final pagoDepositosSinGarantia = g.pagoficha.depositos
          .where((d) => d.garantia != 'Si')
          .fold(0.0, (depSum, d) => depSum + d.deposito);
      final pagoActual = pagoDepositosSinGarantia + g.pagoficha.favorUtilizado;

      if (pagoActual > 0) {
        final saldoGlobalAnterior = g.saldoGlobal - pagoActual;
        final capitalPendienteAnterior = max(
          0,
          g.montoDesembolsado - saldoGlobalAnterior,
        );
        final capitalPendienteActual = max(
          0,
          g.montoDesembolsado - g.saldoGlobal,
        );
        final capitalRecaudadoEsteGrupo =
            (capitalPendienteAnterior - capitalPendienteActual);
        totalCapitalRecaudadoSinGarantia += capitalRecaudadoEsteGrupo;
        totalInteresRecaudadoSinGarantia +=
            (pagoActual - capitalRecaudadoEsteGrupo);
      }
    }

    // === CÁLCULOS CON GARANTÍA (PARA EL TEXTO SECUNDARIO) ===
    final double totalPagofichaConGarantia = reporteData.listaGrupos.fold(
      0.0,
      (sum, g) => sum + g.pagoficha.sumaDeposito + g.pagoficha.favorUtilizado,
    );

    double totalCapitalRecaudadoConGarantia = 0;
    double totalInteresRecaudadoConGarantia = 0;

    for (var g in reporteData.listaGrupos) {
      final pagoActualConGarantia =
          g.pagoficha.sumaDeposito + g.pagoficha.favorUtilizado;
      if (pagoActualConGarantia > 0) {
        final saldoGlobalAnterior = g.saldoGlobal - pagoActualConGarantia;
        final capitalPendienteAnterior = max(
          0,
          g.montoDesembolsado - saldoGlobalAnterior,
        );
        final capitalPendienteActual = max(
          0,
          g.montoDesembolsado - g.saldoGlobal,
        );
        final capitalRecaudado =
            (capitalPendienteAnterior - capitalPendienteActual);
        totalCapitalRecaudadoConGarantia += capitalRecaudado;
        totalInteresRecaudadoConGarantia +=
            (pagoActualConGarantia - capitalRecaudado);
      }
    }

    // === OTROS TOTALES ===
    final double totalMoratoriosPagados = reporteData.listaGrupos.fold(
      0.0, (sum, g) => sum + g.pagoficha.sumaMoratorio);
    final double totalFicha = reporteData.listaGrupos.fold(0.0, (sum, g) => sum + g.montoficha);
    final double restante = totalFicha - totalPagofichaSinGarantia;
    final double nuevoTotalBruto =
        totalPagofichaSinGarantia + reporteData.totalSaldoDisponible + totalMoratoriosPagados;

    return pw.Container(
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6)),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Totales',
              style: pw.TextStyle(
                  color: primaryColor,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Wrap(
              alignment: pw.WrapAlignment.end,
              crossAxisAlignment: pw.WrapCrossAlignment.start,
              runSpacing: 5,
              spacing: 5,
              children: [
                _buildTotalItem('Capital (Período)', reporteData.totalCapital),
                _buildTotalItem('Interés (Período)', reporteData.totalInteres),
                _buildTotalItem('Monto Fichas', totalFicha),
                _buildTotalItem(
                  'Pago Fichas',
                  totalPagofichaSinGarantia,
                  secondaryText: 'Con Garantía: ${currencyFormat.format(totalPagofichaConGarantia)}',
                ),
                _buildTotalItem(
                  'Cap. Rec. (Período)',
                  totalCapitalRecaudadoSinGarantia,
                  secondaryText: 'Con Garantía: ${currencyFormat.format(totalCapitalRecaudadoConGarantia)}',
                ),
                _buildTotalItem(
                  'Interés Rec. (Período)',
                  totalInteresRecaudadoSinGarantia,
                  secondaryText: 'Con Garantía: ${currencyFormat.format(totalInteresRecaudadoConGarantia)}',
                ),
                _buildTotalItem(
                  'S. Favor Disp.',
                  reporteData.totalSaldoDisponible,
                  secondaryText: 'Hist: ${currencyFormat.format(reporteData.totalSaldoFavor)}',
                ),
                _buildTotalItem('Mor. Pag.', totalMoratoriosPagados),
                _buildTotalItem('Total Ideal', totalFicha, isPrimary: true),
                _buildTotalItem('Diferencia', restante, isPrimary: true),
                _buildTotalItem('Total Bruto', nuevoTotalBruto, isPrimary: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGrupoHeader(ReporteContableGrupo grupo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               pw.Text(grupo.grupos,
                  style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
              pw.Text('(Folio: ${grupo.folio})',
                  style: pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
            ]
          )
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Row(
             mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Pago: ${grupo.tipopago}', style: pw.TextStyle(fontSize: 6)),
              pw.SizedBox(width: 8),
              pw.Text('Plazo: ${grupo.plazo}', style: pw.TextStyle(fontSize: 6)),
              pw.SizedBox(width: 8),
              pw.Text('P. Pago: ${grupo.pagoPeriodo}', // Abreviado
                  style: pw.TextStyle(fontSize: 6)),
            ]
          )
        )
      ],
    );
  }

  pw.Widget _buildClientesTable(ReporteContableGrupo grupo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Clientes (${grupo.clientes.length})',
            style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.5),
            1: pw.FlexColumnWidth(1.2),
            2: pw.FlexColumnWidth(1.2),
            3: pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
              children: [
                _buildHeaderCell('Nombre Cliente'),
                _buildHeaderCell('Capital'),
                _buildHeaderCell('Interés'),
                _buildHeaderCell('Total'),
              ],
            ),
            ...grupo.clientes.map((cliente) => pw.TableRow(
                  children: [
                    _buildDataCell(cliente.nombreCompleto),
                    _buildDataCell(
                        currencyFormat.format(cliente.periodoCapital),
                        alignRight: true),
                    _buildDataCell(
                        currencyFormat.format(cliente.periodoInteres),
                        alignRight: true),
                    _buildDataCell(
                        currencyFormat.format(cliente.capitalMasInteres),
                        alignRight: true),
                  ],
                )),
            _buildTotalesRow(grupo.clientes),
          ],
        ),
      ],
    );
  }

  pw.TableRow _buildTotalesRow(List<Cliente> clientes) {
    final totalCapital =
        clientes.fold<double>(0, (sum, item) => sum + item.periodoCapital);
    final totalInteres =
        clientes.fold<double>(0, (sum, item) => sum + item.periodoInteres);
    final totalGeneral =
        clientes.fold<double>(0, (sum, item) => sum + item.capitalMasInteres);
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEDEFFE)),
      children: [
        _buildTotalCell('Totales'),
        _buildTotalCell(currencyFormat.format(totalCapital), alignRight: true),
        _buildTotalCell(currencyFormat.format(totalInteres), alignRight: true),
        _buildTotalCell(currencyFormat.format(totalGeneral), alignRight: true),
      ],
    );
  }

  pw.Widget _buildFinancialInfoSection(ReporteContableGrupo grupo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Info. del Crédito', // Abreviado
            style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(2)),
          child: pw.Column(children: [
            pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _buildFinancialColumn('Garantía', grupo.garantia, isText: true)),
                  pw.SizedBox(width: 4),
                  pw.Expanded(child: _buildFinancialColumn('Tasa', grupo.tazaInteres, isPercentage: true)),
                ]),
            pw.SizedBox(height: 4),
            _buildSimpleFinancialRow('Solicitado', grupo.montoSolicitado, fontSize: 6),
            pw.SizedBox(height: 4),
            _buildSimpleFinancialRow('Desembolsado', grupo.montoDesembolsado, fontSize: 6),
            pw.SizedBox(height: 4),
            _buildSimpleFinancialRow('Interés Total', grupo.interesCredito, fontSize: 6),
            pw.SizedBox(height: 4),
            _buildSimpleFinancialRow('A Recuperar', grupo.montoARecuperar, fontSize: 6),
          ]),
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildFinancialCard('Cap. Semanal', grupo.capitalsemanal),
             pw.SizedBox(width: 2),
            _buildFinancialCard('Int. Semanal', grupo.interessemanal),
             pw.SizedBox(width: 2),
            _buildFinancialCard('Monto Ficha', grupo.montoficha),
          ]
        ),
        pw.SizedBox(height: 3),
         pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildFinancialCard('Mor. Generados', grupo.moratorios.moratoriosAPagar),
            pw.SizedBox(width: 2),
            _buildFinancialCard('Mor. Pagados', grupo.pagoficha.sumaMoratorio),
          ]
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, double value, {required PdfColor color, double fontSize = 7.0}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(currencyFormat.format(value),
            style: pw.TextStyle(
                fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  pw.Widget _buildFinancialColumn(String label, dynamic value,
      {bool isText = false, bool isPercentage = false}) {
    return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 5, color: PdfColors.grey600)),
          pw.SizedBox(height: 1),
          pw.Text(
              isText
                  ? value.toString()
                  : (isPercentage
                      ? '${value.toStringAsFixed(2)}%'
                      : currencyFormat.format(value)),
              style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
        ]);
  }

  pw.Widget _buildSimpleFinancialRow(String label, double value, {double fontSize = 7.0}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize, color: PdfColors.grey800)),
        pw.Text(currencyFormat.format(value), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
      ]
    );
  }

  pw.Widget _buildFinancialCard(String label, double value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(3),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          borderRadius: pw.BorderRadius.circular(2)
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey600)),
            pw.SizedBox(height: 2),
            pw.Text(
              currencyFormat.format(value),
              style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: primaryColor)
            )
          ]
        )
      )
    );
  }

  pw.Widget _buildTotalItem(String label, double value,
      {bool isPrimary = false, String? secondaryText}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 6, color: PdfColors.black)),
        pw.Text(currencyFormat.format(value),
            style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
                color: isPrimary ? primaryColor : PdfColors.black)),
        if(secondaryText != null)
           pw.Text(secondaryText,
            style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey)),
      ]),
    );
  }

  pw.Widget _buildHeaderCell(String text) => pw.Container(
      alignment: pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 6,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor)));

  pw.Widget _buildDataCell(String text, {bool alignRight = false}) =>
      pw.Container(
          alignment:
              alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(text, style: const pw.TextStyle(fontSize: 6), maxLines: 1));

  pw.Widget _buildTotalCell(String text, {bool alignRight = false}) =>
      pw.Container(
          alignment:
              alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(text,
              style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)));

  String _formatDateSafe(String dateString) {
    try {
      if (dateString.isEmpty) return 'N/A';
      return DateFormat('dd/MM/yy').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }
}