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

// Assuming these are defined elsewhere, adjust paths as needed
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/ip.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For baseUrl
import '../utils/app_logger.dart';


class PDFCuentasPago {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF5162F6);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF8BC34A);
  static const PdfColor lightGrey = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor mediumGrey = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor darkGrey = PdfColor.fromInt(0xFF757575);

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
  
  // =======================================================================
  // APLIQUEMOS LOS CAMBIOS AQUÍ
  // =======================================================================
  // <-- CAMBIO 1: La función ahora devuelve 'Future<Uint8List>'.
  // <-- CAMBIO 2: Se eliminó el parámetro 'String savePath'.
  static Future<Uint8List> generar(
    BuildContext context,
    Credito credito,
  ) async {
    try {
      final userData = Provider.of<UserDataProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenauth') ?? '';

      List<CuentaBancaria> cuentasBancarias = [];
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/v1/financiera/cuentasbanco/${userData.idnegocio}'),
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
      final DateTime fechaFin = inputFormat.parse(dateParts[1].trim());
      final String fechaInicioFormateada = outputFormat.format(fechaInicio);
      final String fechaFinFormateada = outputFormat.format(fechaFin);

      await initializeDateFormatting('es_ES', null);

      final logoColorInfo = userData.imagenes.where((img) => img.tipoImagen == 'logoColor').firstOrNull;
      final moneyFacilLogoUrl = logoColorInfo != null ? '$baseUrl/imagenes/subidas/${logoColorInfo.rutaImagen}' : null;
      final moneyFacilLogoBytes = await _loadNetworkImage(moneyFacilLogoUrl);
      final finoraLogoBytes = await _loadAsset('assets/finora.png');

      final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
      final pdf = pw.Document();

      // ... (Toda la lógica de creación de estilos y del build del PDF se mantiene igual)
      // ... (No he pegado toda la UI para no hacer esto demasiado largo, pero no cambia)

      final titleStyle = pw.TextStyle(fontSize: 16,fontWeight: pw.FontWeight.bold,color: primaryColor);
      final headerStyle = pw.TextStyle(fontSize: 12,fontWeight: pw.FontWeight.bold,color: PdfColors.white,);
      final labelStyle = pw.TextStyle(fontSize: 9, color: darkGrey);
      final dataStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black,);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter.copyWith(marginTop: 20, marginBottom: 20, marginLeft: 30, marginRight: 30,),
          build: (pw.Context pdfContext) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header, Título, Info General, Cuentas... todo igual que lo tenías
                 pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (moneyFacilLogoBytes != null)
                      pw.Image(pw.MemoryImage(moneyFacilLogoBytes),height: 40,fit: pw.BoxFit.contain,)
                    else
                      pw.SizedBox(height: 40),
                    pw.Image(pw.MemoryImage(finoraLogoBytes),height: 40,fit: pw.BoxFit.contain,),
                  ],
                ),
                pw.SizedBox(height: 15),
                 pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Ficha De Pago ${credito.tipoPlazo}', style: titleStyle),
                    pw.Text('Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8),),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  decoration: pw.BoxDecoration(color: lightGrey,borderRadius: pw.BorderRadius.circular(8),border: pw.Border.all(color: mediumGrey, width: 0.5),),
                  padding: const pw.EdgeInsets.all(12,),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12,vertical: 10,),
                        decoration: pw.BoxDecoration(color: accentColor,borderRadius: pw.BorderRadius.circular(4),),
                        child: pw.Text('Información General',style: headerStyle,textAlign: pw.TextAlign.center,),
                      ),
                      pw.SizedBox(height: 16,),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildInfoItem('Nombre del Grupo',credito.nombreGrupo,labelStyle,dataStyle,),),
                          pw.SizedBox(width: 20),
                          pw.Expanded(child: _buildInfoItem('Pago ${credito.tipoPlazo}',currencyFormat.format(credito.pagoCuota ?? 0.0),labelStyle,dataStyle,),),
                        ],
                      ),
                      pw.SizedBox(height: 16),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildInfoItem('Fecha de Inicio',fechaInicioFormateada,labelStyle,dataStyle,),),
                          pw.SizedBox(width: 20),
                          pw.Expanded(child: _buildInfoItem('Fecha de Término',fechaFinFormateada,labelStyle,dataStyle,),),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                if (cuentasBancarias.isNotEmpty)
                  _buildCuentasSection(cuentasBancarias,cuentaLogos,headerStyle,labelStyle,dataStyle,),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('Para cualquier duda o aclaración, comuníquese con su asesor financiero',style: pw.TextStyle(fontSize: 8,color: darkGrey,fontStyle: pw.FontStyle.italic,),),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // <-- CAMBIO 3: Eliminamos toda la lógica de guardado y depuración
      // y la reemplazamos con esta única línea.
      return await pdf.save();

    } on FormatException catch (e) {
      AppLogger.log("Error de formato al generar PDF: ${e.message}");
      throw 'Error al formatear datos para el PDF: ${e.message}';
    } catch (e) {
      AppLogger.log("Error generating Ficha Pago Semanal PDF: $e");
      throw 'Failed to generate PDF: ${e.toString()}';
    }
  }

  static pw.Widget _buildInfoItem(String title,String value,pw.TextStyle labelStyle,pw.TextStyle dataStyle,) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: labelStyle),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(color: PdfColors.white,borderRadius: pw.BorderRadius.circular(4),border: pw.Border.all(color: mediumGrey, width: 0.5),),
          child: pw.Text(value,style: dataStyle,textAlign: pw.TextAlign.center,),
        ),
      ],
    );
  }

  static pw.Widget _buildCuentasSection(
    List<CuentaBancaria> cuentas,
    List<Uint8List?> logos,
    pw.TextStyle headerStyle,
    pw.TextStyle labelStyle,
    pw.TextStyle dataStyle,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: lightGrey,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: mediumGrey, width: 0.5),
        /* boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey300,
            offset: const PdfPoint(0, 2),
            blurRadius: 3,
          ),
        ], */
      ),
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Cuentas Bancarias Disponibles',
              style: headerStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 10),
          // Generar filas de 2 tarjetas
          ...List.generate((cuentas.length / 2).ceil(), (rowIndex) {
            final startIdx = rowIndex * 2;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Primera tarjeta en la fila
                  pw.Expanded(
                    child: _buildCuentaCard(
                      cuentas[startIdx],
                      logos[startIdx],
                      labelStyle,
                      dataStyle,
                    ),
                  ),
                  pw.SizedBox(width: 10), // Espacio entre tarjetas
                  // Segunda tarjeta en la fila (si existe)
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
                    pw.Expanded(
                      child: pw.Container(),
                    ), // Espacio vacío para mantener la simetría
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _formatCardNumber(String number) {
    // Elimina cualquier espacio existente
    final cleanNumber = number.replaceAll(' ', '');

    // Agrega un espacio cada 4 caracteres
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
    final formattedDate = DateFormat('dd/MM/yyyy').format(cuenta.fCreacion);

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: mediumGrey, width: 0.5),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey200,
            offset: const PdfPoint(2, 2),
            blurRadius: 3,
          ),
        ],
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Nuevo encabezado con logo y texto juntos
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Institución Financiera:', style: labelStyle),
              pw.SizedBox(width: 10),
              /*   pw.Expanded(
                child: pw.Text(
                  cuenta.nombreBanco,
                  style: dataStyle,
                  maxLines: 1,
                ),
              ), */
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
              pw.SizedBox(height: 5),
              // Como lo indicaste, he dejado comentada la línea de fecha de creación
              // _buildCardItem('Creación:', formattedDate, labelStyle, dataStyle),
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
