import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:finora_app/models/creditos.dart';
import 'package:finora_app/models/cuenta_bancaria.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/ip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class PDFCuentasPago {
  // --- Paleta unificada con PDFControlPagos ---
  static final PdfColor primaryColor = PdfColors.indigo700;
  static final PdfColor accentColor = PdfColors.teal500;
  static final PdfColor lightGrey = PdfColors.grey200;
  static final PdfColor mediumGrey = PdfColors.grey400;
  static final PdfColor darkGrey = PdfColors.grey800;
  static final PdfColor infoBoxBg = PdfColor.fromHex('f2f7fa');

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
      AppLogger.log('Error loading network image: $e');
    }
    return null;
  }

  static Future<Uint8List> generar(
    BuildContext context,
    Credito credito, {
    List<String>? numerosCuentaSeleccionados,
  }) async {
    try {
      final userData = Provider.of<UserDataProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenauth') ?? '';

      List<CuentaBancaria> cuentasBancarias = [];
      try {
        final response = await http.get(
          Uri.parse(
            '$baseUrl/api/v1/financiera/cuentasbanco/${userData.idnegocio}',
          ),
          headers: {'tokenauth': token},
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          cuentasBancarias =
              data.map((item) => CuentaBancaria.fromJson(item)).toList();
        }
      } catch (e) {
        AppLogger.log('Error obteniendo cuentas: $e');
      }

      if (numerosCuentaSeleccionados != null) {
        cuentasBancarias =
            cuentasBancarias
                .where(
                  (cuenta) =>
                      numerosCuentaSeleccionados.contains(cuenta.numeroCuenta),
                )
                .toList();
      }

      List<Uint8List?> cuentaLogos = [];
      for (var cuenta in cuentasBancarias) {
        final imageUrl = '$baseUrl/imagenes/bancos/${cuenta.rutaBanco}';
        cuentaLogos.add(await _loadNetworkImage(imageUrl));
      }

      if (!credito.fechasIniciofin.contains(' - ')) {
        throw 'Invalid date format in fechasIniciofin.';
      }
      final dateParts = credito.fechasIniciofin.split(' - ');
      final inputFormat = DateFormat('yyyy/MM/dd');
      final outputFormat = DateFormat('dd MMMM yyyy', 'es_ES');
      final DateTime fechaInicio = inputFormat.parse(dateParts[0].trim());
      final DateTime DateTimefechaFin = inputFormat.parse(dateParts[1].trim());
      final String fechaInicioFormateada = outputFormat.format(fechaInicio);
      final String fechaFinFormateada = outputFormat.format(DateTimefechaFin);

      await initializeDateFormatting('es_ES', null);

      final logoColorInfo =
          userData.imagenes
              .where((img) => img.tipoImagen == 'logoColor')
              .firstOrNull;
      final moneyFacilLogoUrl =
          logoColorInfo != null
              ? '$baseUrl/imagenes/subidas/${logoColorInfo.rutaImagen}'
              : null;
      final moneyFacilLogoBytes = await _loadNetworkImage(moneyFacilLogoUrl);
      final finoraLogoBytes = await _loadAsset('assets/finora.png');

      final currencyFormat = NumberFormat.currency(
        locale: 'es_MX',
        symbol: '\$',
      );
      final pdf = pw.Document();

      // --- Estilos alineados a PDFControlPagos ---
      final titleStyle = pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#5162F6'),
      );
      final sectionTitleStyle = pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: darkGrey,
      );
      final labelStyle = pw.TextStyle(fontSize: 7, color: darkGrey);
      final dataStyle = pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      );

      // --- Determinación de tipo de crédito basada en su modelo ---
      final bool esIndividual = credito.tipo.toLowerCase() == 'individual';
      final String etiquetaNombre =
          esIndividual ? 'NOMBRE DEL CLIENTE' : 'NOMBRE DEL GRUPO';

      // Si el nombre del cliente se almacena en 'nombreGrupo' para créditos individuales:
      final String valorNombre = credito.nombreGrupo;

      // NOTA: Si necesita extraer el nombre desde la lista 'clientesMontosInd',
      // puede descomentar y adaptar la siguiente línea según las propiedades de su clase ClienteMonto:
      // final String valorNombre = esIndividual && credito.clientesMontosInd.isNotEmpty
      //     ? (credito.clientesMontosInd.first.nombre ?? credito.nombreGrupo)
      //     : credito.nombreGrupo;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter.copyWith(
            marginTop: 20,
            marginBottom: 20,
            marginLeft: 30,
            marginRight: 30,
          ),
          build: (pw.Context pdfContext) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // --- Header igual a PDFControlPagos ---
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: mediumGrey, width: 0.5),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          if (moneyFacilLogoBytes != null)
                            pw.Image(
                              pw.MemoryImage(moneyFacilLogoBytes),
                              height: 40,
                              fit: pw.BoxFit.contain,
                            )
                          else
                            pw.SizedBox(height: 40),
                          pw.Image(
                            pw.MemoryImage(finoraLogoBytes),
                            height: 35,
                            fit: pw.BoxFit.contain,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Ficha De Pago ${credito.tipoPlazo}',
                            style: titleStyle,
                          ),
                          pw.Text(
                            'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),

                // --- Información General (estilo caja, sin header de color) ---
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: infoBoxBg,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INFORMACIÓN GENERAL', style: sectionTitleStyle),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          _buildInfoColumn(
                            etiquetaNombre,
                            valorNombre,
                            flex: 1,
                          ),
                          _buildInfoColumn(
                            'PAGO ${credito.tipoPlazo.toUpperCase()}',
                            currencyFormat.format(credito.pagoCuota ?? 0.0),
                            flex: 1,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          _buildInfoColumn(
                            'FECHA DE INICIO',
                            fechaInicioFormateada,
                            flex: 1,
                          ),
                          _buildInfoColumn(
                            'FECHA DE TÉRMINO',
                            fechaFinFormateada,
                            flex: 1,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),

                if (cuentasBancarias.isNotEmpty)
                  _buildCuentasSection(
                    cuentasBancarias,
                    cuentaLogos,
                    sectionTitleStyle,
                    labelStyle,
                    dataStyle,
                  ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Para cualquier duda o aclaración, comuníquese con su asesor financiero',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: darkGrey,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      return await pdf.save();
    } on FormatException catch (e) {
      AppLogger.log("Error de formato al generar PDF: ${e.message}");
      throw 'Error al formatear datos para el PDF: ${e.message}';
    } catch (e) {
      AppLogger.log("Error generating Ficha Pago Semanal PDF: $e");
      throw 'Failed to generate PDF: ${e.toString()}';
    }
  }

  // Reemplaza a _buildInfoItem, ahora con el mismo patrón que PDFControlPagos
  static pw.Widget _buildInfoColumn(
    String label,
    String value, {
    int flex = 1,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 7, color: darkGrey)),
          pw.SizedBox(height: 2),
          pw.Text(
            value.toUpperCase(),
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCuentasSection(
    List<CuentaBancaria> cuentas,
    List<Uint8List?> logos,
    pw.TextStyle sectionTitleStyle,
    pw.TextStyle labelStyle,
    pw.TextStyle dataStyle,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: infoBoxBg,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: const pw.EdgeInsets.all(15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('CUENTAS BANCARIAS DISPONIBLES', style: sectionTitleStyle),
          pw.SizedBox(height: 10),
          ...List.generate((cuentas.length / 2).ceil(), (rowIndex) {
            final startIdx = rowIndex * 2;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildCuentaCard(
                      cuentas[startIdx],
                      logos[startIdx],
                      labelStyle,
                      dataStyle,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  if (startIdx + 1 < cuentas.length)
                    pw.Expanded(
                      child: _buildCuentaCard(
                        cuentas[startIdx + 1],
                        logos[startIdx + 1],
                        labelStyle,
                        dataStyle,
                      ),
                    )
                  else
                    pw.Expanded(child: pw.Container()),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _formatCardNumber(String number) {
    final cleanNumber = number.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanNumber[i]);
    }
    return buffer.toString();
  }

  static pw.Widget _buildCuentaCard(
    CuentaBancaria cuenta,
    Uint8List? logo,
    pw.TextStyle labelStyle,
    pw.TextStyle dataStyle,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: mediumGrey, width: 0.5),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Institución Financiera:', style: labelStyle),
              pw.SizedBox(width: 10),
              pw.Container(
                width: 50,
                height: 30,
                child:
                    logo != null
                        ? pw.Image(pw.MemoryImage(logo), fit: pw.BoxFit.contain)
                        : pw.Icon(pw.IconData(0xe318)),
              ),
            ],
          ),
          pw.Divider(color: mediumGrey, height: 15),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildCardItem(
                'Nombre del Titular:',
                cuenta.nombreCuenta,
                labelStyle,
                dataStyle,
              ),
              pw.SizedBox(height: 5),
              _buildCardItem(
                'Número de Tarjeta:',
                _formatCardNumber(cuenta.numeroCuenta),
                labelStyle,
                dataStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCardItem(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle dataStyle,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$label ', style: labelStyle),
        pw.Expanded(
          child: pw.Text(
            value,
            style: dataStyle.copyWith(fontSize: 9),
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
