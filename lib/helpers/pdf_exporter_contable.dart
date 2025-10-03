// lib/helpers/pdf_exporter_contable.dart (ACTUALIZADO PARA COINCIDIR CON LA UI)

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
  // === CAMBIO CLAVE: Se añadieron más colores para consistencia ===
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF5162F6);
  static const PdfColor guaranteeColor = PdfColor.fromInt(0xFFE53888);
  static const PdfColor abonoGlobalColor = PdfColor.fromInt(0xFF008080); // Teal
  static const PdfColor favorUsedColor = PdfColor.fromInt(0xFF28a745); // Verde
  static const PdfColor saldoFavorBgColor = PdfColor.fromInt(0xFFe3f2fd); // Azul claro
  static const PdfColor saldoFavorFgColor = PdfColor.fromInt(0xFF0d47a1); // Azul oscuro
  static const PdfColor restanteFichaColor = PdfColor.fromInt(0xFFe9661d);
  static const PdfColor restanteFichaBgColor = PdfColor.fromInt(0xFFfff3e0);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // =========================================================================
  // === SECCIÓN DE DEPÓSITOS MODIFICADA PARA INCLUIR NUEVOS ELEMENTOS ======
  // =========================================================================

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

        // === CAMBIO CLAVE (1/3): Se añade la tarjeta resumen de Saldo a Favor si existe ===
        if (pagoficha.saldofavor > 0)
          _buildSaldoFavorSummaryCardPdf(pagoficha),

        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFedeffe),
              borderRadius: pw.BorderRadius.circular(4)),
          child: _buildSummaryRow('Total depósitos:', pagoficha.sumaDeposito,
              color: primaryColor),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
              color: restanteFichaBgColor,
              borderRadius: pw.BorderRadius.circular(4)),
          child: _buildSummaryRow('Restante ficha:', restanteFicha,
              color: restanteFichaColor),
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
                      child: _buildFinancialColumn(
                          'Saldo Global', grupo.saldoGlobal)),
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

  // === CAMBIO CLAVE (2/3): TARJETA DE DEPÓSITO ACTUALIZADA ===
  // Ahora incluye la etiqueta de "Abono Global"
  // === REEMPLAZA ESTA FUNCIÓN COMPLETA ===
pw.Widget _buildStandardDepositCardPdf(
    Deposito deposito, Pagoficha pagoficha) {
  final isGarantia = deposito.garantia == "Si";
  final isSaldoGlobal = deposito.esSaldoGlobal == "Si";

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
            crossAxisAlignment: pw.CrossAxisAlignment.start, // Alinea a la izquierda
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
                  pw.Expanded(
                      child: _buildDepositoDetailPDF(
                          'Moratorio', deposito.pagoMoratorio)),
                ],
              ),
              if (isGarantia || isSaldoGlobal)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (isGarantia)
                        _buildTagPdf('Garantía', guaranteeColor),

                      if (isGarantia && isSaldoGlobal) 
                        pw.SizedBox(width: 4),

                      if (isSaldoGlobal)
                        _buildTagPdf('Abono Global', abonoGlobalColor),

                      // === CAMBIO CLAVE: AÑADIR TEXTO DESCRIPTIVO PARA ABONO GLOBAL ===
                      if (isSaldoGlobal)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 4),
                          child: pw.Text(
                            '(de ${currencyFormat.format(deposito.saldoGlobal)})',
                            style: const pw.TextStyle(
                              fontSize: 5,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
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

  // === CAMBIO CLAVE (3/3): NUEVO WIDGET PARA LA TARJETA RESUMEN DE SALDO A FAVOR ===
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
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: saldoFavorBgColor,
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

  // =========================================================================
  // El resto del código permanece igual o con cambios menores
  // Se incluye completo para que puedas copiar y pegar todo el archivo.
  // =========================================================================
  
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
    final logoColor =
        userData.imagenes.firstWhereOrNull((img) => img.tipoImagen == 'logoColor');
    final logoUrl =
        logoColor != null ? '$baseUrl/imagenes/subidas/${logoColor.rutaImagen}' : null;
    final financieraLogo = await _loadNetworkImage(logoUrl);

    final ByteData data = await rootBundle.load('assets/finora.png');
    final finoraLogo = data.buffer.asUint8List();

    pdf.addPage(
      pw.MultiPage(
        // === ASEGÚRATE DE QUE ESTÉ ASÍ (SIN .landscape) ===
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

  // === REEMPLAZA ESTA FUNCIÓN COMPLETA ===
  pw.Widget _buildGrupoCard(ReporteContableGrupo grupo) {
    return pw.Container(
      // pw.PageBreak() se puede usar para forzar un salto de página antes de un grupo si es necesario.
      // child: pw.Column(children: [pw.PageBreak(), pw.Container(...)])
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
            
            // Usamos pw.Table en lugar de pw.Row para permitir que el contenido se divida entre páginas.
            // Esta es la corrección clave para el error 'TooManyPagesException'.
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(40), // Columna de Clientes
                1: pw.FlexColumnWidth(30), // Columna Financiera
                2: pw.FlexColumnWidth(30), // Columna de Depósitos
              },
              children: [
                pw.TableRow(
                  // Alineamos el contenido de las celdas en la parte superior.
                  verticalAlignment: pw.TableCellVerticalAlignment.top, 
                  children: [
                    // Columna 1: Clientes (con padding para separarla de la siguiente)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 10),
                      child: _buildClientesTable(grupo),
                    ),
                    // Columna 2: Info Financiera (con padding)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 10),
                      child: _buildFinancialInfoSection(grupo),
                    ),
                    // Columna 3: Depósitos
                    _buildDepositosSection(
                      grupo.pagoficha,
                      grupo.restanteFicha,
                      grupo,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTagPdf(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration:
          pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 6, color: PdfColors.white),
      ),
    );
  }
  
  pw.Widget _buildFavorUtilizadoCardPdf(double favorUtilizado) {
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
                      pw.Text('S. Favor Disponible',
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
                    'Moratorios Generados', grupo.moratorios.moratoriosAPagar),
                pw.SizedBox(width: 5),
                _buildFinancialColumn(
                    'Moratorios Pagados', grupo.pagoficha.sumaMoratorio),
              ]),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, double value,
      {required PdfColor color}) {
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