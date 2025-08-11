// lib/helpers/pdf_exporter_contable.dart (Versión final y corregida)

import 'dart:io';
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
  static const PdfColor guaranteeColor = PdfColor.fromInt(0xFFE53888);
  static const PdfColor favorUsedColor = PdfColor.fromInt(0xFF28a745); // Verde

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
        fileName: 'reporte_contable_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Uint8List> _loadAsset(String path) async {
    final ByteData data = await rootBundle.load(path);
    return data.buffer.asUint8List();
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

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final logoColor = userData.imagenes.firstWhereOrNull((img) => img.tipoImagen == 'logoColor');
    final logoUrl = logoColor != null ? '$baseUrl/imagenes/subidas/${logoColor.rutaImagen}' : null;
    final financieraLogo = await _loadNetworkImage(logoUrl);
    final finoraLogo = await _loadAsset('assets/finora.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
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
      ),
    );

    return pdf;
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

  pw.Widget _buildGrupoCard(ReporteContableGrupo grupo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildGrupoHeader(grupo),
            pw.Divider(color: PdfColors.grey400, height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 40, child: _buildClientesTable(grupo)),
                pw.SizedBox(width: 10),
                pw.Expanded(flex: 30, child: _buildFinancialInfoSection(grupo)),
                pw.SizedBox(width: 10),
                pw.Expanded(
                    flex: 30,
                    child: _buildDepositosSection(
                        grupo.pagoficha, grupo.restanteFicha, grupo)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === CAMBIO CLAVE (1/3): SECCIÓN DE DEPÓSITOS MODIFICADA ===
  pw.Widget _buildDepositosSection(
      Pagoficha pagoficha, double restanteFicha, ReporteContableGrupo grupo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Depósitos',
                style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor)),
            pw.Text('Fecha prog: ${_formatDateSafe(pagoficha.fechasPago)}',
                style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Column(
            children: (pagoficha.depositos.isEmpty &&
                    pagoficha.favorUtilizado == 0)
                ? [
                    pw.Container(
                        height: 50,
                        alignment: pw.Alignment.center,
                        child: pw.Text('Sin depósitos',
                            style:
                                pw.TextStyle(color: PdfColors.grey, fontSize: 6)))
                  ]
                : [
                    ...pagoficha.depositos.map((deposito) {
                      // Se pasa `pagoficha` para la lógica interna si fuera necesaria
                      return _buildStandardDepositCardPdf(deposito, pagoficha);
                    }).toList(),
                    if (pagoficha.favorUtilizado > 0)
                      _buildFavorUtilizadoCardPdf(
                          pagoficha.favorUtilizado, pagoficha.fechasPago),
                  ]),
        
        // --- AQUÍ ESTÁ EL CAMBIO PRINCIPAL ---
        // Se añade la tarjeta resumen de Saldo a Favor si existe.
        if (pagoficha.saldofavor > 0)
          _buildSaldoFavorSummaryCardPdf(pagoficha),

        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFedeffe),
              borderRadius: pw.BorderRadius.circular(4)),
          child: _buildSummaryRow('Total depósitos:', pagoficha.sumaDeposito,
              color: const PdfColor.fromInt(0xFF5465f6)),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFfff3e0),
              borderRadius: pw.BorderRadius.circular(4)),
          child: _buildSummaryRow('Restante ficha:', restanteFicha,
              color: const PdfColor.fromInt(0xFFe9661d)),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey300)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Resumen Global',
                  style: pw.TextStyle(
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                      child:
                          _buildFinancialColumn('Saldo Global', grupo.saldoGlobal)),
                  pw.SizedBox(width: 5),
                  pw.Expanded(
                      child: _buildFinancialColumn(
                          'Restante Global', grupo.restanteGlobal)),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  // === CAMBIO CLAVE (2/3): TARJETA DE DEPÓSITO SIMPLIFICADA ===
  // Se ha eliminado el detalle del Saldo a Favor de aquí.
  pw.Widget _buildStandardDepositCardPdf(
      Deposito deposito, Pagoficha pagoficha) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFdce0fd),
                borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    topRight: pw.Radius.circular(4))),
            child: pw.Text(
                'Fecha depósito: ${_formatDateSafe(deposito.fechaDeposito)}',
                style: pw.TextStyle(fontSize: 6),
                textAlign: pw.TextAlign.center),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                        child: _buildDepositoDetailPDF('Depósito',
                            deposito.deposito,
                            depositoCompleto: pagoficha.depositoCompleto)),
                    pw.SizedBox(width: 5),
                    // --- El Saldo a Favor fue removido de aquí ---
                    // pw.Expanded(child: _buildSaldoFavorDetailPdf(pagoficha)),
                    // pw.SizedBox(width: 5),
                    pw.Expanded(
                        child: _buildDepositoDetailPDF(
                            'Moratorio', deposito.pagoMoratorio)),
                  ],
                ),
                if (deposito.garantia == "Si")
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(top: 4),
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: pw.BoxDecoration(
                          color: guaranteeColor,
                          borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text('Garantía',
                          style: pw.TextStyle(
                              fontSize: 6, color: PdfColors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === CAMBIO CLAVE (3/3): NUEVO WIDGET PARA LA TARJETA RESUMEN ===
  // Este widget replica la lógica de la UI de Flutter para mostrar el saldo a favor.
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
      secondaryText = 'de ${currencyFormat.format(pagoficha.saldofavor)} total';
    } else {
      title = 'S. Favor Generado';
      primaryText = currencyFormat.format(pagoficha.saldofavor);
      secondaryText = 'disponible';
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFe3f2fd), // Un azul claro
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFbbdefb)),
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
                    color: const PdfColor.fromInt(0xFF0d47a1), // Azul oscuro
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
              color: const PdfColor.fromInt(0xFF0d47a1), // Azul oscuro
              decoration: decoration,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFavorUtilizadoCardPdf(double favorUtilizado, String fechaOriginal) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: favorUsedColor),
          borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            decoration: pw.BoxDecoration(
                color: favorUsedColor,
                borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    topRight: pw.Radius.circular(4))),
            child: pw.Text('Abono con Saldo a Favor',
                style: pw.TextStyle(
                    fontSize: 6,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
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

  pw.Widget _buildDepositoDetailPDF(String label, double value,
      {double? depositoCompleto}) {
    // bool showCompletoInfo = false;
    // if (label == 'Depósito' &&
    //     depositoCompleto != null &&
    //     depositoCompleto > 0) {
    //   const double epsilon = 0.01;
    //   showCompletoInfo = (value - depositoCompleto).abs() > epsilon;
    // }
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
    return pw.Container(
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6)),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Totales',
              style: pw.TextStyle(
                  color: primaryColor,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                _buildTotalItem('Capital Total', reporteData.totalCapital),
                _buildTotalItem('Interés Total', reporteData.totalInteres),
                _buildTotalItem('Monto Fichas', reporteData.totalFicha),
                _buildTotalItem('Pago Fichas', reporteData.totalPagoficha),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Saldo Favor Disp.',
                          style:
                              const pw.TextStyle(fontSize: 6, color: PdfColors.black)),
                      pw.Text(
                          currencyFormat.format(reporteData.totalSaldoDisponible),
                          style: pw.TextStyle(
                              fontSize: 6,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black)),
                      pw.Text(
                          '(Hist: ${currencyFormat.format(reporteData.totalSaldoFavor)})',
                          style:
                              const pw.TextStyle(fontSize: 5, color: PdfColors.grey)),
                    ],
                  ),
                ),
                _buildTotalItem('Moratorios', reporteData.saldoMoratorio),
                pw.SizedBox(width: 40),
                _buildTotalItem('Total Ideal', reporteData.totalTotal,
                    isPrimary: true),
                _buildTotalItem('Diferencia', reporteData.restante,
                    isPrimary: true),
                _buildTotalItem('Total Bruto', reporteData.sumaTotalCapMoraFav,
                    isPrimary: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // =========================================================================
  // El resto de los métodos no requerían cambios
  // =========================================================================

  pw.Widget _buildGrupoHeader(ReporteContableGrupo grupo) {
    return pw.Row(
      children: [
        pw.Text(grupo.grupos,
            style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(width: 9),
        pw.Text('(Folio: ${grupo.folio})',
            style: pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
        pw.Spacer(),
        pw.Text('Pago: ${grupo.tipopago}', style: pw.TextStyle(fontSize: 6)),
        pw.SizedBox(width: 15),
        pw.Text('Plazo: ${grupo.plazo}', style: pw.TextStyle(fontSize: 6)),
        pw.SizedBox(width: 15),
        pw.Text('Periodo Pago: ${grupo.pagoPeriodo}',
            style: pw.TextStyle(fontSize: 6)),
      ],
    );
  }

  pw.Widget _buildClientesTable(ReporteContableGrupo grupo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Clientes',
            style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.white),
              children: [
                _buildHeaderCell('Nombre Cliente'),
                _buildHeaderCell('Capital'),
                _buildHeaderCell('Interés'),
                _buildHeaderCell('Capital + Interés'),
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
      decoration: const pw.BoxDecoration(color: PdfColor(0.95, 0.95, 1.0)),
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
        pw.Text('Información del Crédito',
            style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(2)),
          child: pw.Column(children: [
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildFinancialColumn('Garantía', grupo.garantia,
                      isText: true),
                  pw.SizedBox(width: 5),
                  _buildFinancialColumn('Tasa', grupo.tazaInteres,
                      isPercentage: true),
                ]),
            pw.SizedBox(height: 6),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildFinancialColumn(
                      'Monto Solicitado', grupo.montoSolicitado),
                  pw.SizedBox(width: 5),
                  _buildFinancialColumn(
                      'Monto Desembolsado', grupo.montoDesembolsado),
                ]),
            pw.SizedBox(height: 6),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildFinancialColumn('Interés Total', grupo.interesCredito),
                  pw.SizedBox(width: 5),
                  _buildFinancialColumn(
                      'Monto a Recuperar', grupo.montoARecuperar),
                ]),
          ]),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(2)),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildFinancialColumn(
                    '${grupo.tipopago == "SEMANAL" ? "Capital Semanal" : "Capital Quincenal"}',
                    grupo.capitalsemanal),
                pw.SizedBox(width: 5),
                _buildFinancialColumn(
                    '${grupo.tipopago == "SEMANAL" ? "Interés Semanal" : "Interés Quincenal"}',
                    grupo.interessemanal),
                pw.SizedBox(width: 5),
                _buildFinancialColumn('Monto Ficha', grupo.montoficha),
              ]),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(2)),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildFinancialColumn(
                    'Moratorios Generados', grupo.moratorios.moratoriosAPagar ?? 0.0),
                pw.SizedBox(width: 5),
                _buildFinancialColumn(
                    'Moratorios Pagados', grupo.pagoficha.sumaMoratorio ?? 0.0),
              ]),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, double value, {required PdfColor color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 6, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(currencyFormat.format(value),
            style: pw.TextStyle(
                fontSize: 6, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  pw.Widget _buildFinancialColumn(String label, dynamic value,
      {bool isText = false, bool isPercentage = false}) {
    return pw.Expanded(
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 5, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(
              isText
                  ? value.toString()
                  : (isPercentage
                      ? '${value.toString()}%'
                      : currencyFormat.format(value)),
              style: pw.TextStyle(fontSize: 6)),
        ]));
  }

  pw.Widget _buildTotalItem(String label, double value,
      {bool isPrimary = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6),
      child: pw.Column(children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 6, color: PdfColors.black)),
        pw.Text(currencyFormat.format(value),
            style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
                color: isPrimary ? primaryColor : PdfColors.black)),
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
          child: pw.Text(text, style: const pw.TextStyle(fontSize: 6)));

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
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }
}