// lib/pdf/pdf_resumen_credito.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:finora_app/ip.dart';
import 'package:finora_app/models/calendario_response.dart';
import 'package:finora_app/models/cliente_monto.dart';
import 'package:finora_app/models/creditos.dart';
import 'package:finora_app/models/pago.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/pago_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class PDFResumenCredito {
  static final format = NumberFormat("#,##0.00");
  static final dateFormat = DateFormat('dd/MM/yyyy');
  static final darkGrey = PdfColors.grey800;
  static final PdfColor primaryColor = PdfColors.indigo700;
  static final PdfColor accentColor = PdfColors.teal500;
  static final PdfColor lightGrey = PdfColors.grey200;
  static final PdfColor mediumGrey = PdfColors.grey400;
  static final PdfColor darkGreyColor = PdfColors.grey800;

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

  static pw.TextStyle sectionTitleStyle = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: darkGreyColor,
  );

  static pw.TextStyle infoColumnValueStyle = pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
  );

  // En: lib/pdf/pdf_resumen_credito.dart

  // ▼▼▼ REEMPLAZA ESTA FUNCIÓN COMPLETA (VERSIÓN ROBUSTA) ▼▼▼
  // En: lib/pdf/pdf_resumen_credito.dart

  // ▼▼▼ REEMPLAZA ESTA FUNCIÓN COMPLETA (VERSIÓN DEFINITIVA) ▼▼▼
  static Future<List<Pago>> _fetchPagosData(String idCredito) async {
    // 1. Creamos una instancia del servicio que ya funciona en tu app.
    final PagoService pagoService = PagoService();

    try {
      // 2. Llamamos al método del servicio, igual que en ControlPagosTab.
      final ApiResponse<CalendarioResponse> apiResponse = await pagoService
          .getCalendarioPagos(idCredito);

      // 3. Verificamos si la respuesta fue exitosa y tiene datos.
      if (apiResponse.success && apiResponse.data != null) {
        // 4. Si todo salió bien, devolvemos la lista de pagos que está dentro del objeto de respuesta.
        return apiResponse.data!.pagos;
      } else {
        // 5. Si el servicio reportó un error, lo lanzamos para que se muestre en el PDF.
        throw Exception(
          apiResponse.error ?? "Respuesta no exitosa del servidor",
        );
      }
    } catch (e) {
      // 6. Atrapamos cualquier otro error (de red, etc.) y lo reportamos.
      AppLogger.log('Error en _fetchPagosData al usar PagoService: $e');
      throw Exception('Error al obtener datos de pagos: ${e.toString()}');
    }
  }

  // =========================================================================
  // AQUÍ ESTÁN LOS CAMBIOS
  // =========================================================================
  // <-- CAMBIO 1: La función ahora devuelve 'Future<Uint8List>'.
  // <-- CAMBIO 2: Se eliminó el parámetro 'String savePath'.
  static Future<Uint8List> generar(
    BuildContext context,
    Credito credito,
  ) async {
    try {
      final currencyFormat = NumberFormat.currency(
        locale: 'es_MX',
        symbol: '\$',
      );

      if (!credito.fechasIniciofin.contains(' - ')) {
        throw 'Formato de fecha inválido.';
      }

      final partes = credito.fechasIniciofin.split(' - ');
      final formatEntrada = DateFormat('yyyy/MM/dd');
      final formatSalida = DateFormat('dd/MM/yyyy');
      final fechaInicio = formatEntrada.parse(partes[0].trim());
      final fechaFin = formatEntrada.parse(partes[1].trim());
      final fechaInicioFormateada = formatSalida.format(fechaInicio);
      final fechaFinFormateada = formatSalida.format(fechaFin);

      final pdf = pw.Document();
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
      final logoColor =
          userData.imagenes
              .where((img) => img.tipoImagen == 'logoColor')
              .firstOrNull;
      final logoUrl =
          logoColor != null
              ? '$baseUrl/imagenes/subidas/${logoColor.rutaImagen}'
              : null;
      final financieraLogo = await _loadNetworkImage(logoUrl);
      final finora_appLogo = await _loadAsset('assets/finora.png');

      List<Pago> pagosData = [];
      String? errorPagos;
      try {
        if (credito.idcredito == null || credito.idcredito!.isEmpty) {
          throw Exception("ID de crédito no disponible.");
        }
        pagosData = await _fetchPagosData(credito.idcredito!);
      } catch (e) {
        AppLogger.log("Error al obtener datos de pagos para el PDF: $e");
        errorPagos = e.toString();
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
          header:
              (context) => _buildDocumentHeader(
                credito,
                titleStyle,
                finora_appLogo,
                financieraLogo,
              ),
          footer:
              (context) =>
                  _buildCompactFooter(), // Asumo que esta función existe
          build:
              (context) => [
                pw.SizedBox(height: 15),
                _buildGroupInfo(
                  credito,
                  sectionTitleStyle,
                  currencyFormat,
                ), // Asumo que existen
                pw.SizedBox(height: 15),
                _buildLoanInfo(
                  credito,
                  sectionTitleStyle,
                  fechaInicioFormateada,
                  fechaFinFormateada,
                  currencyFormat,
                ),
                pw.SizedBox(height: 15),
                if (credito.clientesMontosInd.isNotEmpty) ...[
                  _buildClientesSection(
                    credito.clientesMontosInd,
                    credito,
                    currencyFormat,
                  ),
                  pw.SizedBox(height: 15),
                  if (errorPagos != null)
                    pw.Padding(
                      padding: pw.EdgeInsets.symmetric(vertical: 10),
                      child: pw.Text(
                        "Error al cargar calendario de pagos: $errorPagos",
                        style: pw.TextStyle(color: PdfColors.red, fontSize: 9),
                      ),
                    )
                  else if (pagosData.isNotEmpty) ...[
                    pw.NewPage(),
                    pw.SizedBox(height: 20),
                    pw.Text("CALENDARIO DE PAGOS", style: sectionTitleStyle),
                    pw.SizedBox(height: 10),
                    _buildPagosSection(pagosData, currencyFormat),
                    pw.SizedBox(height: 15),
                    
                // ▼▼▼ MODIFICA ESTE BLOQUE ▼▼▼
                
                () {
                  final List<dynamic> todasLasRenovaciones = pagosData
                      .expand((pago) => pago.renovacionesPendientes)
                      .toList();

                  if (todasLasRenovaciones.isNotEmpty) {
                    return pw.Column(
                      children: [
                        // <--- PASA LA LISTA DE CLIENTES DEL CRÉDITO AQUÍ
                        _buildRenovacionesSection(
                          todasLasRenovaciones, 
                          credito.clientesMontosInd, // <--- PARÁMETRO AÑADIDO
                          currencyFormat
                        ),
                        pw.SizedBox(height: 15),
                      ]
                    );
                  }
                  
                  return pw.SizedBox.shrink();
                }(),
                
                // ▲▲▲ FIN DE LA MODIFICACIÓN ▲▲▲

                  ] else
                    pw.Padding(
                      padding: pw.EdgeInsets.symmetric(vertical: 10),
                      child: pw.Text(
                        "No hay datos del calendario de pagos para mostrar.",
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                ],
                pw.SizedBox(height: 30),
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

  // --- El resto de tus funciones helper (sin cambios) ---
  // He dejado solo los stubs/placeholders para que veas que existen,
  // pero el código dentro de ellas no cambia en absoluto.

  static pw.Widget _buildDocumentHeader(
    Credito credito,
    pw.TextStyle titleStyle,
    Uint8List finora_appLogo,
    Uint8List? financieraLogo,
  ) {
    // Tu código aquí sin cambios
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
              pw.Text(
                'Resumen de crédito',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#5162F6'),
                ),
              ),
              pw.Text(
                'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        '${credito.nombreGrupo} | ${credito.detalles}',
                        style: pw.TextStyle(
                          fontSize: 6,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Container(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [_buildStatusBadge(credito.estado)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Copiado exactamente de ControlPagos
  static pw.Widget _buildGroupInfo(
    Credito credito,
    pw.TextStyle sectionTitleStyle,
    final currencyFormat,
  ) {
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
          pw.Row(
            children: [
              _buildInfoColumn(
                'NOMBRE DEL GRUPO',
                credito.nombreGrupo,
                flex: 2,
              ),
              _buildInfoColumn('CICLO', credito.detalles, flex: 2),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoColumn(
                'NOMBRE DE LA PRESIDENTA',
                _getPresidenta(credito.clientesMontosInd),
                flex: 2,
              ),
              _buildInfoColumn(
                'NOMBRE DE LA TESORERA',
                _getTesorera(credito.clientesMontosInd),
                flex: 2,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoColumn('NOMBRE DEL ASESOR', credito.asesor, flex: 2),
              _buildInfoColumn(
                'MONTO TOTAL',
                '${currencyFormat.format(credito.montoTotal)}',
                flex: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Copiado exactamente de ControlPagos
  static String _getPresidenta(List<ClienteMonto> clientes) {
    for (var cliente in clientes) {
      if (cliente.cargo == "Presidente/a") {
        return cliente.nombreCompleto;
      }
    }
    return "No asignada";
  }

  // Copiado exactamente de ControlPagos
  static String _getTesorera(List<ClienteMonto> clientes) {
    for (var cliente in clientes) {
      if (cliente.cargo == "Tesorero/a") {
        return cliente.nombreCompleto;
      }
    }
    return "No asignada";
  }

  // Copiado exactamente de ControlPagos
  static pw.Widget _buildLoanInfo(
    Credito credito,
    pw.TextStyle sectionTitleStyle,
    String fechaInicioFormateada,
    String fechaFinFormateada,
    final currencyFormat,
  ) {
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
          pw.Text('DETALLES DEL CRÉDITO', style: sectionTitleStyle),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildInfoColumn('DÍA DE PAGO', credito.diaPago, flex: 1),
              _buildInfoColumn('PLAZO', '${credito.plazo} SEMANAS', flex: 1),
              _buildInfoColumn(
                'MONTO FICHA',
                '${currencyFormat.format(credito.pagoCuota)}',
                flex: 1,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoColumn(
                'MONTO DESEMBOLSADO',
                '${currencyFormat.format(credito.montoDesembolsado)}',
                flex: 1,
              ),
              _buildInfoColumn('GARANTÍA', '${credito.garantia}', flex: 1),
              _buildInfoColumn(
                'GARANTÍA MONTO',
                '${currencyFormat.format(credito.montoGarantia)}',
                flex: 1,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoColumn(
                'TIPO DE CRÉDITO',
                '${credito.tipo}${credito.tipo == "Grupal" ? " - AVAL SOLIDARIO" : ""}',
                flex: 1,
              ),
              _buildInfoColumn(
                'TASA DE INTERÉS MENSUAL',
                '${credito.ti_mensual}',
                flex: 1,
              ),
              _buildInfoColumn(
                'INTERÉS TOTAL',
                '${currencyFormat.format(credito.interesTotal)}',
                flex: 1,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoColumn(
                'FECHA INICIO DE CONTRATO',
                fechaInicioFormateada,
                flex: 1,
              ),
              _buildInfoColumn(
                'FECHA TÉRMINO DE CONTRATO',
                fechaFinFormateada,
                flex: 1,
              ),
              _buildInfoColumn(
                'MONTO A RECUPERAR',
                '${currencyFormat.format(credito.montoMasInteres)}',
                flex: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Método actualizado con el mismo estilo de ControlPagos (con parámetro flex)
  static pw.Widget _buildInfoColumn(
    String label,
    String value, {
    int flex = 1,
    pw.TextStyle? valueStyle,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 7, // Mismo tamaño que ControlPagos
              color: darkGreyColor, // Mismo color que ControlPagos
            ),
          ),
          pw.SizedBox(height: 2), // Mismo espaciado que ControlPagos
          pw.Text(
            value.toUpperCase(),
            style:
                valueStyle ??
                pw.TextStyle(
                  fontSize: 8, // Mismo tamaño que ControlPagos
                  fontWeight: pw.FontWeight.bold, // Mismo peso que ControlPagos
                ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatusBadge(String status) {
    PdfColor statusColor;
    switch (status.toLowerCase()) {
      case 'activo':
      case 'vigente':
        statusColor = PdfColors.green;
        break;
      case 'finalizado':
      case 'pagado':
        statusColor = PdfColors.blue800;
        break;
      case 'vencido':
      case 'moroso':
        statusColor = PdfColors.red;
        break;
      case 'pendiente':
        statusColor = PdfColors.orange;
        break;
      default:
        statusColor = PdfColors.grey;
    }

    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: statusColor,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        status.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 6,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableHeader(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(color: PdfColors.grey300),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildClientesSection(
    List<ClienteMonto> clientesMontosInd,
    Credito credito,
    final currencyFormat,
  ) {
    final sumTotalRedondeado = credito.pagoCuota * credito.plazo;

    // Definir colores para la tabla (mismos que _paymentTable)
    final headerColor = PdfColor.fromHex('f2f7fa');
    final rowEvenColor = PdfColors.white;
    final rowOddColor = PdfColors.grey100;
    final totalRowColor = PdfColor.fromHex('f2f7fa');
    final borderColor = PdfColors.blue800;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      /*  decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('f2f7fa'),
        borderRadius: pw.BorderRadius.circular(8),
      ), */
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('MONTOS INDIVIDUALES', style: sectionTitleStyle),
          pw.SizedBox(height: 10),
          pw.Column(
            children: [
              // Encabezado de la tabla
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 50,
                    child: pw.Container(
                      height: 30,
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
                  pw.Expanded(
                    flex: 220,
                    child: pw.Container(
                      height: 30,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: headerColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'CLIENTE',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 100,
                    child: pw.Container(
                      height: 30,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: headerColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'M. INDIV.',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 100,
                    child: pw.Container(
                      height: 30,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: headerColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'CAPITAL',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 100,
                    child: pw.Container(
                      height: 30,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: headerColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'INTERÉS',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 120,
                    child: pw.Container(
                      height: 30,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: headerColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'TOT. CAPITAL',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 120,
                    child: pw.Container(
                      height: 30,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: headerColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'TOT. INTERÉS',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 120,
                    child: pw.Container(
                      height: 30,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: headerColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'CAP + INT',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 120,
                    child: pw.Container(
                      height: 30,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: headerColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'PAGO TOTAL',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Filas de clientes
              ...clientesMontosInd.asMap().entries.map((entry) {
                int index = entry.key;
                ClienteMonto cliente = entry.value;
                bool isEven = index % 2 == 0;

                return pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 50,
                      child: pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 0.5),
                          color: isEven ? rowEvenColor : rowOddColor,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${index + 1}',
                            style: pw.TextStyle(
                              fontSize: 6,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 220,
                      child: pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 0.5),
                          color: isEven ? rowEvenColor : rowOddColor,
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(
                              cliente.nombreCompleto,
                              style: pw.TextStyle(fontSize: 6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 100,
                      child: pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 0.5),
                          color: isEven ? rowEvenColor : rowOddColor,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${currencyFormat.format(cliente.capitalIndividual)}',
                            style: pw.TextStyle(fontSize: 6),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 100,
                      child: pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 0.5),
                          color: isEven ? rowEvenColor : rowOddColor,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${currencyFormat.format(cliente.periodoCapital)}',
                            style: pw.TextStyle(fontSize: 6),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 100,
                      child: pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 0.5),
                          color: isEven ? rowEvenColor : rowOddColor,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${currencyFormat.format(cliente.periodoInteres)}',
                            style: pw.TextStyle(fontSize: 6),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 120,
                      child: pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 0.5),
                          color: isEven ? rowEvenColor : rowOddColor,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${currencyFormat.format(cliente.totalCapital)}',
                            style: pw.TextStyle(fontSize: 6),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 120,
                      child: pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 0.5),
                          color: isEven ? rowEvenColor : rowOddColor,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${currencyFormat.format(cliente.totalIntereses)}',
                            style: pw.TextStyle(fontSize: 6),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 120,
                      child: pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 0.5),
                          color: isEven ? rowEvenColor : rowOddColor,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${currencyFormat.format(cliente.capitalMasInteres)}',
                            style: pw.TextStyle(fontSize: 6),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 120,
                      child: pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 0.5),
                          color: isEven ? rowEvenColor : rowOddColor,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${currencyFormat.format(cliente.total)}',
                            style: pw.TextStyle(fontSize: 6),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),

              // Fila de totales
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 50,
                    child: pw.Container(
                      height: 25,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: totalRowColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '', // Celda en blanco
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 220,
                    child: pw.Container(
                      height: 25,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: totalRowColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'TOTALES',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 100,
                    child: pw.Container(
                      height: 25,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: totalRowColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '${currencyFormat.format(clientesMontosInd.fold(0.0, (sum, c) => sum + c.capitalIndividual))}',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 100,
                    child: pw.Container(
                      height: 25,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: totalRowColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '${currencyFormat.format(clientesMontosInd.fold(0.0, (sum, c) => sum + c.periodoCapital))}',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 100,
                    child: pw.Container(
                      height: 25,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: totalRowColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '${currencyFormat.format(clientesMontosInd.fold(0.0, (sum, c) => sum + c.periodoInteres))}',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 120,
                    child: pw.Container(
                      height: 25,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: totalRowColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '${currencyFormat.format(clientesMontosInd.fold(0.0, (sum, c) => sum + c.totalCapital))}',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 120,
                    child: pw.Container(
                      height: 25,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: totalRowColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '${currencyFormat.format(clientesMontosInd.fold(0.0, (sum, c) => sum + c.totalIntereses))}',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 120,
                    child: pw.Container(
                      height: 25,
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
                  pw.Expanded(
                    flex: 120,
                    child: pw.Container(
                      height: 25,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        color: totalRowColor,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '${currencyFormat.format(sumTotalRedondeado)}',
                          style: pw.TextStyle(
                            fontSize: 6,
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
        ],
      ),
    );
  }

  // --- NUEVA FUNCIÓN HELPER PARA FORMATEAR FECHAS ---
  static String _formatPdfDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    try {
      // Intentar parsear formatos comunes que podrías recibir
      if (dateString.contains('-')) {
        // Formato YYYY-MM-DD (común en APIs)
        final parsedDate = DateFormat('yyyy-MM-dd').parse(dateString);
        return dateFormat.format(parsedDate); // dateFormat es dd/MM/yyyy
      } else if (dateString.contains('/')) {
        // Formato YYYY/MM/DD
        final parsedDate = DateFormat('yyyy/MM/dd').parse(dateString);
        return dateFormat.format(parsedDate);
      } else if (dateString.length == 8 && int.tryParse(dateString) != null) {
        // Formato YYYYMMDD
        final parsedDate = DateFormat('yyyyMMdd').parse(dateString);
        return dateFormat.format(parsedDate);
      }
      // Si no es un formato conocido o falla el parseo, devolver original o un placeholder
      return dateString;
    } catch (e) {
      AppLogger.log("Error parseando fecha '$dateString' para PDF: $e");
      return dateString; // Devolver original en caso de error de parseo
    }
  }

  // --- MÉTODO PARA CONSTRUIR LA SECCIÓN DE PAGOS ---
  // --- MÉTODO ACTUALIZADO PARA CONSTRUIR LA SECCIÓN DE PAGOS ---
  // --- MÉTODO ACTUALIZADO PARA CONSTRUIR LA SECCIÓN DE PAGOS CON SALDO EN CONTRA ---
  // En: lib/pdf/pdf_resumen_credito.dart

  // ▼▼▼ REEMPLAZA ESTA FUNCIÓN COMPLETA (VERSIÓN SOLO PARA PDF) ▼▼▼
  static pw.Widget _buildPagosSection(List<Pago> pagos, final currencyFormat) {
    final headerColor = PdfColor.fromHex('f2f7fa');
    final rowEvenColor = PdfColors.white;
    final rowOddColor = PdfColors.grey100;
    final borderColor = PdfColors.blueGrey300;
    final headerTextStyle = pw.TextStyle(
      fontSize: 6,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey900,
    );
    final cellTextStyle = pw.TextStyle(fontSize: 6);

    List<pw.TableRow> tableRows = [];

    // Encabezado
    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: headerColor),
        children: [
          _paddedCell('SEM.', headerTextStyle, alignment: pw.Alignment.center),
          _paddedCell(
            'F. PROGRAMADA',
            headerTextStyle,
            alignment: pw.Alignment.center,
          ),
          _paddedCell(
            'MONTO FICHA',
            headerTextStyle,
            alignment: pw.Alignment.centerRight,
          ),
          _paddedCell(
            'F. REALIZADO',
            headerTextStyle,
            alignment: pw.Alignment.center,
          ),
          _paddedCell(
            'PAGOS',
            headerTextStyle,
            alignment: pw.Alignment.centerRight,
          ),
          // --- CAMBIO: Encabezados actualizados ---
          _paddedCell(
            'S. FAVOR GENERADO',
            headerTextStyle, // Renombrado para claridad
            alignment: pw.Alignment.centerRight,
          ),
          _paddedCell(
            'S. FAVOR UTILIZADO',
            headerTextStyle, // <-- NUEVA COLUMNA
            alignment: pw.Alignment.centerRight,
          ),
          _paddedCell(
            'S. EN CONTRA',
            headerTextStyle,
            alignment: pw.Alignment.centerRight,
          ),
          _paddedCell(
            'MORAT. GENERADOS',
            headerTextStyle,
            alignment: pw.Alignment.centerRight,
          ),
          _paddedCell(
            'MORAT. PAGADOS',
            headerTextStyle,
            alignment: pw.Alignment.centerRight,
          ),
          _paddedCell(
            'TIPO PAGO',
            headerTextStyle,
            alignment: pw.Alignment.center,
          ),
          _paddedCell(
            'ESTADO',
            headerTextStyle,
            alignment: pw.Alignment.center,
          ),
        ],
      ),
    );

    // Totales acumulados
    double totalCuotas = 0.0;
    double totalAbonos = 0.0;
    double totalSaldoFavorGenerado = 0.0;
    double totalFavorUtilizado = 0.0; // <-- NUEVO ACUMULADOR
    double totalSaldoContra = 0.0;
    double totalMoratoriosGenerados = 0.0;
    double totalMoratoriosPagados = 0.0;

    // Filas de datos
    for (int i = 0; i < pagos.length; i++) {
      final pago = pagos[i];
      final bool isEven = i % 2 == 0;
      final bgColor = isEven ? rowEvenColor : rowOddColor;

      String fechaProgramadaFormateada = _formatPdfDate(pago.fechaPago);

      String fechaRealizadoFormateada = "N/A";
      if (pago.abonos.isNotEmpty) {
        List<String> fechasFormateadas = [];
        for (var abono in pago.abonos) {
          if (abono['fechaDeposito'] != null) {
            String fechaFormateada = _formatPdfDate(
              abono['fechaDeposito'] as String?,
            );
            fechasFormateadas.add(fechaFormateada);
          }
        }
        if (fechasFormateadas.isNotEmpty) {
          fechaRealizadoFormateada = fechasFormateadas.join('\n');
        }
      }

      String tipoPagoDisplay = pago.tipoPago ?? '';
      if (tipoPagoDisplay.isEmpty ||
          tipoPagoDisplay.toLowerCase() == "sin asignar") {
        tipoPagoDisplay = "N/A";
      }

      // Procesar abonos
      String pagosDetallados = "N/A";
      double totalAbonosPago = 0.0;
      if (pago.abonos.isNotEmpty) {
        List<String> detalles = [];
        for (var abono in pago.abonos) {
          double montoDeposito = 0.0;
          if (abono['deposito'] != null) {
            if (abono['deposito'] is String) {
              montoDeposito = double.tryParse(abono['deposito']) ?? 0.0;
            } else if (abono['deposito'] is num) {
              montoDeposito = (abono['deposito'] as num).toDouble();
            }
          }
          totalAbonosPago += montoDeposito;
          String montoFormateado = '${currencyFormat.format(montoDeposito)}';
          String esGarantia = (abono['garantia'] == 'Si') ? " (G)" : "";
          detalles.add("$montoFormateado$esGarantia");
        }
        pagosDetallados = detalles.join('\n');
      }

      // Calcular saldo en contra
      double saldoContra = 0.0;
      if (pago.semana != 0) {
        // La deuda de la semana incluye capital, interés y moratorios generados
        double montoDebe =
            pago.capitalMasInteres + (pago.moratorios?.moratorios ?? 0);
        // Lo que se ha cubierto son los abonos + el saldo a favor que se haya utilizado
        double totalCubierto = totalAbonosPago + (pago.favorUtilizado ?? 0.0);
        if (totalCubierto < montoDebe) {
          saldoContra = montoDebe - totalCubierto;
        }
      }

      // Procesar moratorios (ya lo tenías bien)
      double moratoriosGenerados = 0.0;
      double moratoriosPagados = 0.0;
      if (pago.pagosMoratorios.isNotEmpty) {
        for (var moratorio in pago.pagosMoratorios) {
          moratoriosGenerados +=
              (moratorio['moratorioAPagar'] as num?)?.toDouble() ?? 0.0;
          moratoriosPagados +=
              (moratorio['sumaMoratorios'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // Acumuladores solo si no es semana 0
      if (pago.semana != 0) {
        totalCuotas += pago.capitalMasInteres;
        totalAbonos += totalAbonosPago;
        totalSaldoFavorGenerado += pago.saldoFavorOriginalGenerado ?? 0.0;
        totalFavorUtilizado += pago.favorUtilizado ?? 0.0; // <-- AÑADIDO
        totalSaldoContra += saldoContra;
        totalMoratoriosGenerados += moratoriosGenerados;
        totalMoratoriosPagados += moratoriosPagados;
      }

      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: bgColor),
          children: [
            _paddedCell(
              pago.semana.toString(),
              cellTextStyle,
              alignment: pw.Alignment.center,
            ),
            _paddedCell(
              fechaProgramadaFormateada,
              cellTextStyle,
              alignment: pw.Alignment.center,
            ),
            _paddedCell(
              pago.semana == 0
                  ? 'N/A'
                  : '${currencyFormat.format(pago.capitalMasInteres)}',
              cellTextStyle,
              alignment: pw.Alignment.centerRight,
            ),
            _paddedCell(
              fechaRealizadoFormateada,
              cellTextStyle,
              alignment: pw.Alignment.center,
            ),
            _paddedCell(
              pagosDetallados,
              cellTextStyle,
              alignment: pw.Alignment.centerRight,
            ),
            // --- CAMBIO: Celdas de datos actualizadas ---
            _paddedCell(
              '${currencyFormat.format(pago.saldoFavorOriginalGenerado ?? 0.0)}',
              cellTextStyle,
              alignment: pw.Alignment.centerRight,
            ),
            _paddedCell(
              '${currencyFormat.format(pago.favorUtilizado ?? 0.0)}',
              cellTextStyle,
              alignment: pw.Alignment.centerRight,
            ), // <-- NUEVA CELDA
            _paddedCell(
              '${currencyFormat.format(saldoContra)}',
              cellTextStyle,
              alignment: pw.Alignment.centerRight,
            ),
            _paddedCell(
              '${currencyFormat.format(moratoriosGenerados)}',
              cellTextStyle,
              alignment: pw.Alignment.centerRight,
            ),
            _paddedCell(
              '${currencyFormat.format(moratoriosPagados)}',
              cellTextStyle,
              alignment: pw.Alignment.centerRight,
            ),
            _paddedCell(
              tipoPagoDisplay,
              cellTextStyle,
              alignment: pw.Alignment.center,
            ),
            _paddedCell(
              pago.estado,
              cellTextStyle,
              alignment: pw.Alignment.center,
            ),
          ],
        ),
      );
    }

    // Fila de totales
    // BORRAR/COMENTAR la TableRow de "TOTALES" dentro de tableRows
    // tableRows.add(pw.TableRow(... TOTALES ...)); // <- quitar

    // ... después de haber construido tableRows y antes del return:
    final columnWeights = <double>[
      0.5, // 0: Sem.
      1.0, // 1: F. Programada
      0.9, // 2: Monto Ficha
      1.0, // 3: F. Realizado
      1.0, // 4: Pagos
      0.8, // 5: S. Favor Generado
      0.8, // 6: S. Favor Utilizado
      0.8, // 7: S. En Contra
      0.8, // 8: Morat. Generados
      0.8, // 9: Morat. Pagados
      0.8, // 10: Tipo Pago
      0.7, // 11: Estado
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // tu tabla con todas las filas de datos (sin la fila de totales)
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.5),
          children: tableRows,
          columnWidths: {
            0: pw.FlexColumnWidth(0.5),
            1: pw.FlexColumnWidth(1.0),
            2: pw.FlexColumnWidth(0.9),
            3: pw.FlexColumnWidth(1.0),
            4: pw.FlexColumnWidth(1.0),
            5: pw.FlexColumnWidth(0.8),
            6: pw.FlexColumnWidth(0.8),
            7: pw.FlexColumnWidth(0.8),
            8: pw.FlexColumnWidth(0.8),
            9: pw.FlexColumnWidth(0.8),
            10: pw.FlexColumnWidth(0.8),
            11: pw.FlexColumnWidth(0.7),
          },
        ),

        // --- Fila de totales simulada ---
        pw.LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = constraints!.maxWidth;
            final totalWeight = columnWeights.fold(0.0, (a, b) => a + b);
            final pixelWidths =
                columnWeights
                    .map((w) => (w / totalWeight) * tableWidth)
                    .toList();

            // helper para crear una celda (bordes y padding)
            pw.Widget buildCell(
              String text,
              double w, {
              pw.Alignment align = pw.Alignment.center,
              bool drawTop = true,
            }) {
              return pw.Container(
                width: w,
                padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                alignment: align,
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: borderColor, width: 0.5),
                    top:
                        drawTop
                            ? pw.BorderSide(color: borderColor, width: 0.5)
                            : pw.BorderSide.none,
                    bottom: pw.BorderSide(color: borderColor, width: 0.5),
                    right: pw.BorderSide(color: borderColor, width: 0.5),
                  ),
                  color: headerColor, // mismo color de totales
                ),
                child: pw.Text(
                  text,
                  style: headerTextStyle,
                  textAlign: pw.TextAlign.center,
                ),
              );
            }

            // Primera celda "TOTALES" ocupa la suma del ancho de las dos primeras columnas:
            final mergedFirstWidth = pixelWidths[0] + pixelWidths[1];

            // Ahora construimos la fila: primero la celda fusionada, luego las demás
            final List<pw.Widget> children = [];

            // Celda fusionada (ocupa 2 col)
            children.add(
              pw.Container(
                width: mergedFirstWidth,
                padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: borderColor, width: 0.5),
                    top:
                        pw
                            .BorderSide
                            .none, // si la tabla ya tiene borde inferior, evita doble línea
                    bottom: pw.BorderSide(color: borderColor, width: 0.5),
                    right: pw.BorderSide(color: borderColor, width: 0.5),
                  ),
                  color: headerColor,
                ),
                child: pw.Text('TOTALES', style: headerTextStyle),
              ),
            );

            // puesto 2 en adelante usamos los totales que tenías calculados
            final otherValues = <String>[
              '${currencyFormat.format(totalCuotas)}', // col 2
              '-', // col 3 (F. Realizado)
              '${currencyFormat.format(totalAbonos)}',
              '${currencyFormat.format(totalSaldoFavorGenerado)}',
              '${currencyFormat.format(totalFavorUtilizado)}',
              '${currencyFormat.format(totalSaldoContra)}',
              '${currencyFormat.format(totalMoratoriosGenerados)}',
              '${currencyFormat.format(totalMoratoriosPagados)}',
              '-', // col 10 (Tipo Pago)
              '-', // col 11 (Estado)
            ];

            // Note: otherValues corresponde a las columnas 2..11 (10 items)
            for (int i = 2; i < 12; i++) {
              final idx = i - 2;
              children.add(
                buildCell(
                  otherValues[idx],
                  pixelWidths[i],
                  align: pw.Alignment.centerRight,
                  drawTop: false,
                ),
              );
            }

            return pw.Container(
              // Si quieres que no aparezca una línea doble entre la tabla y esta fila,
              // ajusta el top/bottom de las decoraciones según necesites
              child: pw.Row(children: children),
            );
          },
        ),
      ],
    );
  }

  // Helper para celdas con padding
  static pw.Widget _paddedCell(
    String text,
    pw.TextStyle style, {
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 5,
      ), // Aumentar padding vertical
      alignment: alignment,
      child: pw.Text(text, style: style, softWrap: true),
    );
  }

  static pw.Widget _buildCompactFooter() {
    // Implementa el footer según tu necesidad
    return pw.Container();
  }





  // ▼▼▼ PASO 1: AÑADE ESTA NUEVA FUNCIÓN COMPLETA ▼▼▼
  /// Construye la sección de clientes a renovar con adeudo para el siguiente crédito.
  // ▼▼▼ REEMPLAZA LA FUNCIÓN ANTERIOR POR ESTA VERSIÓN CORREGIDA ▼▼▼
  /// Construye la sección de clientes a renovar con adeudo para el siguiente crédito.
  static pw.Widget _buildRenovacionesSection(
    List<dynamic> renovaciones,
    List<ClienteMonto> clientes, // <--- CAMBIO 1: Añadimos la lista de clientes
    final currencyFormat,
  ) {
    if (renovaciones.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final headerColor = PdfColor.fromHex('f2f7fa');
    final rowEvenColor = PdfColors.white;
    final rowOddColor = PdfColors.grey100;
    final totalRowColor = PdfColor.fromHex('f2f7fa');
    final borderColor = PdfColors.blueGrey300;
    final headerTextStyle = pw.TextStyle(
      fontSize: 7,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey900,
    );
    final cellTextStyle = pw.TextStyle(fontSize: 7);

    final double totalAdeudo = renovaciones.fold(0.0, (sum, item) {
      // <--- CAMBIO 2: Usamos 'descuento' en lugar de 'monto'
      // El valor viene como num, así que lo convertimos a double.
      final monto = (item.descuento as num?)?.toDouble() ?? 0.0;
      return sum + monto;
    });

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("CLIENTES A RENOVAR CON ADEUDO", style: sectionTitleStyle),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: headerColor),
              children: [
                _paddedCell('NOMBRE DEL CLIENTE', headerTextStyle),
                _paddedCell(
                  'SALDO PARA SIGUIENTE CRÉDITO',
                  headerTextStyle,
                  alignment: pw.Alignment.centerRight,
                ),
              ],
            ),
            ...renovaciones.asMap().entries.map((entry) {
              final int index = entry.key;
              final dynamic renovacion = entry.value;
              final bool isEven = index % 2 == 0;
              final bgColor = isEven ? rowEvenColor : rowOddColor;

              // <--- CAMBIO 3: Lógica para obtener el nombre y el monto ---
              String nombre = 'Cliente no encontrado';
              try {
                // Buscamos en la lista de clientes del crédito el que coincida con el id.
                final clienteEncontrado = clientes.firstWhere(
                  (c) => c.idclientes == renovacion.idclientes,
                );
                nombre = clienteEncontrado.nombreCompleto;
              } catch (e) {
                // Si no se encuentra (muy raro), dejamos el mensaje por defecto.
                AppLogger.log("PDF Renovación: No se encontró el cliente con ID ${renovacion.idclientes}");
              }
              
              final double monto = (renovacion.descuento as num?)?.toDouble() ?? 0.0;

              return pw.TableRow(
                decoration: pw.BoxDecoration(color: bgColor),
                children: [
                  _paddedCell(nombre, cellTextStyle),
                  _paddedCell(
                    currencyFormat.format(monto),
                    cellTextStyle,
                    alignment: pw.Alignment.centerRight,
                  ),
                ],
              );
            }).toList(),
            pw.TableRow(
              decoration: pw.BoxDecoration(color: totalRowColor),
              children: [
                _paddedCell(
                  'TOTAL',
                  headerTextStyle,
                  alignment: pw.Alignment.centerRight,
                ),
                _paddedCell(
                  currencyFormat.format(totalAdeudo),
                  headerTextStyle,
                  alignment: pw.Alignment.centerRight,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
