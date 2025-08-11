import 'dart:io';
import 'package:finora_app/models/cliente_monto.dart';
import 'package:finora_app/models/creditos.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:finora_app/ip.dart';
import '../utils/app_logger.dart';


class PDFControlPagos {
  static final PdfColor primaryColor = PdfColors.indigo700;
  static final PdfColor accentColor = PdfColors.teal500;
  static final PdfColor lightGrey = PdfColors.grey200;
  static final PdfColor mediumGrey = PdfColors.grey400;
  static final PdfColor darkGrey = PdfColors.grey800;

  static Future<Uint8List> _loadAsset(String path) async {
    final ByteData data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  static Future<Uint8List?> _loadNetworkImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      AppLogger.log('Error cargando imagen desde URL: $e');
    }
    return null;
  }

  // =========================================================================
  // AQUÍ ESTÁN LOS CAMBIOS PRINCIPALES
  // =========================================================================
  // <-- CAMBIO 1: La función ahora devuelve 'Future<Uint8List>'.
  // <-- CAMBIO 2: Se eliminó el parámetro 'String savePath'.
  static Future<Uint8List> generar(
      BuildContext context, Credito credito) async {
    try {
      final currencyFormat =
          NumberFormat.currency(locale: 'es_MX', symbol: '\$');

      if (!credito.fechasIniciofin.contains(' - ')) {
        throw 'Formato de fecha inválido. Use "yyyy/MM/dd - yyyy/MM/dd"';
      }

      final partes = credito.fechasIniciofin.split(' - ');
      if (partes.length != 2) {
        throw 'Formato debe ser: fecha_inicio - fecha_fin';
      }

      final formatEntrada = DateFormat('yyyy/MM/dd');
      final formatSalida = DateFormat('dd/MM/yyyy');
      final fechaInicio = formatEntrada.parse(partes[0].trim());
      final fechaFin = formatEntrada.parse(partes[1].trim());
      final fechaInicioFormateada = formatSalida.format(fechaInicio);
      final fechaFinFormateada = formatSalida.format(fechaFin);
      
      final pdf = pw.Document();
      final fechas = _generarFechas(fechaInicio, credito.plazo);
      final titleStyle = pw.TextStyle(
        fontSize: 20,
        fontWeight: pw.FontWeight.bold,
        color: primaryColor,
      );
      final sectionTitleStyle = pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: darkGrey,
      );

      final userData = Provider.of<UserDataProvider>(context, listen: false);
      final logoColor = userData.imagenes
          .where((img) => img.tipoImagen == 'logoColor')
          .firstOrNull;
      final logoUrl = logoColor != null
          ? '$baseUrl/imagenes/subidas/${logoColor.rutaImagen}'
          : null;
      final financieraLogo = await _loadNetworkImage(logoUrl);
      final finora_appLogo = await _loadAsset('assets/finora.png');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
          header: (context) => _buildDocumentHeader(
            credito,
            titleStyle,
            finora_appLogo,
            financieraLogo,
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            pw.SizedBox(height: 15),
            _buildGroupInfo(credito, sectionTitleStyle, fechaInicioFormateada,
                fechaFinFormateada, currencyFormat),
            pw.SizedBox(height: 15),
            _buildLoanInfo(credito, sectionTitleStyle, fechaInicioFormateada,
                fechaFinFormateada, currencyFormat),
            pw.SizedBox(height: 25),
            ..._buildPaymentTables(fechas, credito, currencyFormat),
            pw.SizedBox(height: 30),
            _buildSignatures(credito),
          ],
        ),
      );

      // <-- CAMBIO 3: En lugar de guardar en un archivo, devolvemos los bytes del PDF.
      return await pdf.save();

    } on FormatException catch (e) {
      throw 'Error en fecha: ${e.message}';
    } catch (e) {
      throw 'Error al generar PDF: ${e.toString()}';
    }
  }

  // --- El resto del código de la clase no necesita ningún cambio ---
  // --- Es idéntico a lo que ya tienes ---

  static List<DateTime> _generarFechas(DateTime startDate, int weeks) {
    return List.generate(
      weeks,
      (i) => startDate.add(Duration(days: 7 * (i + 1))),
    );
  }

  static pw.Widget _buildDocumentHeader(
    //... (tu código aquí, sin cambios)
    Credito credito,
    pw.TextStyle titleStyle,
    Uint8List finora_appLogo,
    Uint8List? financieraLogo) {
      return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: mediumGrey, width: 0.5)),
        ),
        child: pw.Column(
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
                  pw.MemoryImage(finora_appLogo),
                  width: 120,
                  height: 40,
                  fit: pw.BoxFit.contain,
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Control de pago',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#5162F6'),
                    )),
                pw.Text(
                  'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ],
        ),
      );
    }

  static pw.Widget _buildGroupInfo(
      Credito credito,
      pw.TextStyle sectionTitleStyle,
      String fechaInicioFormateada, // <- Añadir parámetros
      String fechaFinFormateada, // <- aquí
      final currencyFormat) {
    final format = NumberFormat("#,##0.00");

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('f2f7fa'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('INFORMACIÓN DEL GRUPO', style: sectionTitleStyle),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _buildInfoColumn('NOMBRE DEL GRUPO', credito.nombreGrupo, flex: 2),
            _buildInfoColumn('CICLO', credito.detalles, flex: 2),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _buildInfoColumn('NOMBRE DE LA PRESIDENTA',
                _getPresidenta(credito.clientesMontosInd),
                flex: 2),
            _buildInfoColumn('NOMBRE DE LA TESORERA',
                _getTesorera(credito.clientesMontosInd),
                flex: 2),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _buildInfoColumn('NOMBRE DEL ASESOR', credito.asesor, flex: 2),
            _buildInfoColumn(
                'MONTO TOTAL', '${currencyFormat.format(credito.montoTotal)}',
                flex: 2),
          ]),
        ],
      ),
    );
  }

  // Helper functions to get specific roles
  static String _getPresidenta(List<ClienteMonto> clientes) {
    // Find the client with the "Presidenta" cargo (role)
    for (var cliente in clientes) {
      if (cliente.cargo == "Presidente/a") {
        return cliente.nombreCompleto;
      }
    }
    // If not found, return empty string or default message
    return "No asignada";
  }

  static String _getTesorera(List<ClienteMonto> clientes) {
    // Find the client with the "Tesorera" cargo (role)
    for (var cliente in clientes) {
      if (cliente.cargo == "Tesorero/a") {
        return cliente.nombreCompleto;
      }
    }
    // If not found, return empty string or default message
    return "No asignada";
  }

  static pw.Widget _buildLoanInfo(
      Credito credito,
      pw.TextStyle sectionTitleStyle,
      String fechaInicioFormateada, // <- Añadir parámetros
      String fechaFinFormateada, // <- aquí
      final currencyFormat) {
    final format = NumberFormat("#,##0.00");
    final partesFecha = credito.fechasIniciofin.split(' - ');

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('f2f7fa'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('DETALLES DEL CRÉDITO', style: sectionTitleStyle),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _buildInfoColumn('DÍA DE PAGO', credito.diaPago, flex: 1),
            _buildInfoColumn('PLAZO', '${credito.plazo} SEMANAS', flex: 1),
            _buildInfoColumn(
                'MONTO FICHA', '${currencyFormat.format(credito.pagoCuota)}',
                flex: 1),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _buildInfoColumn('MONTO DESEMBOLSADO',
                '${currencyFormat.format(credito.montoDesembolsado)}',
                flex: 1),
            _buildInfoColumn('GARANTÍA', '${credito.garantia}', flex: 1),
            _buildInfoColumn('GARANTÍA MONTO',
                '${currencyFormat.format(credito.montoGarantia)}',
                flex: 1),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _buildInfoColumn('TIPO DE CRÉDITO',
                '${credito.tipo}${credito.tipo == "Grupal" ? " - AVAL SOLIDARIO" : ""}',
                flex: 1),
            _buildInfoColumn('TASA DE INTERÉS MENSUAL', '${credito.ti_mensual}',
                flex: 1),
            _buildInfoColumn('INTERÉS TOTAL',
                '${currencyFormat.format(credito.interesTotal)}',
                flex: 1),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _buildInfoColumn('FECHA INICIO DE CONTRATO', fechaInicioFormateada,
                flex: 1),
            _buildInfoColumn('FECHA TÉRMINO DE CONTRATO', fechaFinFormateada,
                flex: 1),
            _buildInfoColumn('MONTO A RECUPERAR',
                '${currencyFormat.format(credito.montoMasInteres)}',
                flex: 1),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoColumn(String label, String value,
      {int flex = 1, pw.TextStyle? valueStyle}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 7,
              color: darkGrey,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value.toUpperCase(),
            style: valueStyle ??
                pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildPaymentTables(
      List<DateTime> dates, Credito credito, final currencyFormat) {
    final blocks = _splitDates(dates, 4);
    final widgets = <pw.Widget>[];

    /*  widgets.add(pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: pw.Text(
        'REGISTRO DE PAGOS SEMANALES',
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: darkGrey,
        ),
      ),
    )); */

    //widgets.add(pw.SizedBox(height: 15));

    for (var i = 0; i < blocks.length; i++) {
      // Calcular el número de semana inicial para este bloque
      int startWeek = i * 4 + 1;

      widgets.add(
        pw.Container(
          decoration: pw.BoxDecoration(
            boxShadow: [
              pw.BoxShadow(
                color: PdfColors.grey300,
                offset: const PdfPoint(2, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: pw.Column(
            children: [
              _paymentTable(blocks[i], credito, startWeek, currencyFormat),
              if (i < blocks.length - 1) pw.SizedBox(height: 15), // Espaciado
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  // Modify the _paymentTable function to split "PAGO SOLIDARIO" into two columns
  static pw.Widget _paymentTable(
      List<DateTime> dates, Credito credito, int startWeek,
      final currencyFormat
      ) {
    // Calcular totales
    double totalMontoAutorizado = 0;
    //double totalPagoSemanal = 0;

    for (var member in credito.clientesMontosInd) {
      totalMontoAutorizado += member.capitalIndividual;
    }

    //totalPagoSemanal += credito.pagoCuota;

    // Definir colores para la tabla
    final headerColor = PdfColor.fromHex('f2f7fa');
    final subheaderColor = PdfColor.fromHex('f2f7fa');
    final rowEvenColor = PdfColors.white;
    final rowOddColor = PdfColors.grey100;
    final totalRowColor = PdfColor.fromHex('f2f7fa');
    final borderColor = PdfColors.blue800;

    return pw.Column(
      children: [
        // Primera fila - Encabezados principales
        pw.Row(
          children: [
            // Columna No.
            pw.Expanded(
              flex: 30,
              child: pw.Container(
                height: 40,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  color: headerColor,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'No.',
                    style: pw.TextStyle(
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),
            ),
            // Columna NOMBRE DE INTEGRANTES
            pw.Expanded(
              flex: 170,
              child: pw.Container(
                height: 40,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  color: headerColor,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'NOMBRE DE INTEGRANTES',
                    style: pw.TextStyle(
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),
            ),
            // Columna MONTO AUTORIZADO
            pw.Expanded(
              flex: 50,
              child: pw.Container(
                height: 40,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  color: headerColor,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'MONTO\nAUTORIZADO',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),
            ),
            // Columna PAGO SEMANAL
            pw.Expanded(
              flex: 50,
              child: pw.Container(
                height: 40,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  color: headerColor,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'PAGO\nSEMANAL',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),
            ),
            // Celdas de semanas
            for (var i = 0; i < dates.length; i++)
              pw.Expanded(
                flex: 70,
                child: pw.Column(
                  children: [
                    // Primera fila - Encabezado de semana
                    pw.Container(
                      height: 20,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: headerColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'SEMANA ${startWeek + i}\nFECHA: ${DateFormat('dd/MM/yyyy').format(dates[i])}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                    // Segunda fila - PAGO SOLIDARIO dividido en dos columnas
                    pw.Row(
                      children: [
                        // Left column: "PAGO"
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            height: 20,
                            decoration: pw.BoxDecoration(
                              border:
                                  pw.Border.all(color: borderColor, width: 0.5),
                              color: subheaderColor,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'PAGO',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 4,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue900,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Right column: "SOLIDARIO"
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            height: 20,
                            decoration: pw.BoxDecoration(
                              border:
                                  pw.Border.all(color: borderColor, width: 0.5),
                              color: subheaderColor,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'SOLIDARIO',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 4,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),

        // Filas de datos - usando el loop original en lugar del método _buildMemberRow
        for (var memberIndex = 0;
            memberIndex < credito.clientesMontosInd.length;
            memberIndex++)
          pw.Row(
            children: [
              // No.
              pw.Expanded(
                flex: 30,
                child: pw.Container(
                  height: 20,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor, width: 0.5),
                    color: memberIndex % 2 == 0 ? rowEvenColor : rowOddColor,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '${memberIndex + 1}-',
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                ),
              ),
              // Nombre
              pw.Expanded(
                flex: 170,
                child: pw.Container(
                  height: 20,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor, width: 0.5),
                    color: memberIndex % 2 == 0 ? rowEvenColor : rowOddColor,
                  ),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    credito.clientesMontosInd[memberIndex].nombreCompleto,
                    style: pw.TextStyle(fontSize: 6),
                  ),
                ),
              ),
              // Monto Autorizado
              pw.Expanded(
                flex: 50,
                child: pw.Container(
                  height: 20,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor, width: 0.5),
                    color: memberIndex % 2 == 0 ? rowEvenColor : rowOddColor,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '${currencyFormat.format(credito.clientesMontosInd[memberIndex].capitalIndividual)}',
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                ),
              ),
              // Pago Semanal
              pw.Expanded(
                flex: 50,
                child: pw.Container(
                  height: 20,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor, width: 0.5),
                    color: memberIndex % 2 == 0 ? rowEvenColor : rowOddColor,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '${currencyFormat.format(credito.clientesMontosInd[memberIndex].capitalMasInteres)}',
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                ),
              ),
              // Celdas de pago
              for (var date in dates)
                pw.Expanded(
                  flex: 70,
                  child: pw.Row(
                    children: [
                      // Left cell for "PAGO" column
                      pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          height: 20,
                          padding: const pw.EdgeInsets.all(2),
                          decoration: pw.BoxDecoration(
                            border:
                                pw.Border.all(color: borderColor, width: 0.5),
                            color: memberIndex % 2 == 0
                                ? rowEvenColor
                                : rowOddColor,
                          ),
                          child: pw.Container(),
                        ),
                      ),
                      // Right cell for "SOLIDARIO" column
                      pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          height: 20,
                          padding: const pw.EdgeInsets.all(2),
                          decoration: pw.BoxDecoration(
                            border:
                                pw.Border.all(color: borderColor, width: 0.5),
                            color: memberIndex % 2 == 0
                                ? rowEvenColor
                                : rowOddColor,
                          ),
                          child: pw.Container(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

        // Fila de totales
        pw.Row(
          children: [
            // No.
            pw.Expanded(
              flex: 30,
              child: pw.Container(
                height: 20,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  color: totalRowColor,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '',
                    style: pw.TextStyle(
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Total
            pw.Expanded(
              flex: 170,
              child: pw.Container(
                height: 20,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  color: totalRowColor,
                ),
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'TOTAL:',
                  style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
            ),
            // Total Monto Autorizado
            pw.Expanded(
              flex: 50,
              child: pw.Container(
                height: 20,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  color: totalRowColor,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '${currencyFormat.format(totalMontoAutorizado)}',
                    style: pw.TextStyle(
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),
            ),
            // Total Pago Semanal
            pw.Expanded(
              flex: 50,
              child: pw.Container(
                height: 20,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  color: totalRowColor,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '${currencyFormat.format(credito.pagoCuota)}',
                    style: pw.TextStyle(
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),
            ),
            // Celdas de pago vacías para totales
            for (var i = 0; i < dates.length; i++)
              pw.Expanded(
                flex: 70,
                child: pw.Row(
                  children: [
                    // Left total cell for "PAGO" column
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 0.5),
                          color: totalRowColor,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '',
                            style: pw.TextStyle(
                              fontSize: 6,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Right total cell for "SOLIDARIO" column
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 0.5),
                          color: totalRowColor,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '',
                            style: pw.TextStyle(
                              fontSize: 6,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  static List<List<DateTime>> _splitDates(List<DateTime> dates, int chunkSize) {
    return List.generate(
      (dates.length / chunkSize).ceil(),
      (i) => dates.sublist(
        i * chunkSize,
        i * chunkSize + chunkSize > dates.length
            ? dates.length
            : i * chunkSize + chunkSize,
      ),
    );
  }

  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool isDateCell = false,
    int rowSpan = 1,
    pw.TextStyle? style,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Center(
        child: pw.Text(
          text,
          textAlign: isDateCell ? pw.TextAlign.center : textAlign,
          style: style ??
              pw.TextStyle(
                fontSize: 6,
                fontWeight:
                    isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
        ),
      ),
    );
  }

  static pw.Widget _buildEmptyPaymentCell() {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Container(
        height: 18,
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: mediumGrey.shade(0.3), width: 0.5),
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildSignatures(Credito credito) {
    // Get names for each role
    final presidentaName = _getPresidenta(credito.clientesMontosInd);
    final tesoreraName = _getTesorera(credito.clientesMontosInd);
    final asesorName = credito.asesor;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        children: [
          // Add significant space to push everything down
          pw.SizedBox(height: 70),
          // First add the signature lines
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _signatureLine('PRESIDENTA', presidentaName),
              _signatureLine('TESORERA', tesoreraName),
              _signatureLine('ASESOR', asesorName),
            ],
          ),
          // Add the text below the signatures
          pw.SizedBox(height: 30),
          pw.Text(
            'FIRMAN DE CONFORMIDAD',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
              color: PdfColor.fromHex('#5162F6'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureLine(String role, String name) {
    return pw.Column(
      children: [
        pw.Container(
          width: 120,
          height: 1,
          color: darkGrey,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          role,
          style: pw.TextStyle(
            fontSize: 10,
            color: darkGrey,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          name.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8,
            color: darkGrey,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: pw.TextStyle(
          fontSize: 9,
          color: mediumGrey,
        ),
      ),
    );
  }
}
