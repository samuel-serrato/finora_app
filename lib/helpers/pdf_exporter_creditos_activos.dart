import 'dart:io';
import 'package:flutter/material.dart'; // Necesario para el BuildContext
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Nuevos imports para la carga de logos y providers
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:finora_app/ip.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/models/reporte_creditos_activos.dart';

class PdfExporterCreditosActivos {
  final BuildContext context; // <--- Agregamos el BuildContext
  final List<ReporteCreditoActivo> listaCreditos;
  final NumberFormat currencyFormat;
  final String nombreUsuario;

  PdfExporterCreditosActivos({
    required this.context, // <--- Requerido en el constructor
    required this.listaCreditos,
    required this.currencyFormat,
    required this.nombreUsuario,
  });

  // --- PALETA DE COLORES ---
  static const PdfColor colorPrimary = PdfColor.fromInt(0xFF5162F6);
  static const PdfColor colorHeaderBg = PdfColor.fromInt(0xFFE8EAF6);
  static const PdfColor colorBackground = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor colorCard = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor colorTextPrimary = PdfColor.fromInt(0xFF333333);
  static const PdfColor colorTextSecondary = PdfColor.fromInt(0xFF757575);
  static const PdfColor colorGreen = PdfColor.fromInt(0xFF4CAF50);
  static const PdfColor colorOrange = PdfColor.fromInt(0xFFFF9800);
  static const PdfColor colorRed = PdfColor.fromInt(0xFFF44336);
  static const PdfColor colorBarTime = PdfColor.fromInt(0xFF0D668F);

  // Limpieza de texto por si acaso la fuente por defecto falla con acentos
  String _limpiarTexto(String input) {
    if (input.isEmpty) return "";
    return input
        .replaceAll('Á', 'A')
        .replaceAll('á', 'a')
        .replaceAll('É', 'E')
        .replaceAll('é', 'e')
        .replaceAll('Í', 'I')
        .replaceAll('í', 'i')
        .replaceAll('Ó', 'O')
        .replaceAll('ó', 'o')
        .replaceAll('Ú', 'U')
        .replaceAll('ú', 'u')
        .replaceAll('Ñ', 'N')
        .replaceAll('ñ', 'n')
        .replaceAll('•', '-') // Evitar falla de la viñeta
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }

  // Helper para descargar la imagen de la financiera
  Future<Uint8List?> _loadNetworkImage(String? url) async {
    if (url == null) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // --- CÁLCULOS TOTALES ---
  Map<String, double> _calcularTotales() {
    double sumaPagado = 0;
    double sumaRestanteCr = 0;
    double sumaMoraRestante = 0;
    double sumaGranTotal = 0;

    for (var c in listaCreditos) {
      final double restCr = c.montoMasInteres - c.totalPagos;
      final double moraGen = c.estadoCredito?.acumulado ?? 0.0;
      final double moraPag = c.totalMora;
      final double moraRestante = (moraGen - moraPag).clamp(
        0.0,
        double.infinity,
      );

      sumaPagado += c.totalPagos;
      sumaRestanteCr += restCr;
      sumaMoraRestante += moraRestante;
      sumaGranTotal += (restCr + moraRestante);
    }
    return {
      'pagado': sumaPagado,
      'restante': sumaRestanteCr,
      'mora': sumaMoraRestante,
      'total': sumaGranTotal,
    };
  }

  Future<void> exportToPdf() async {
    // 1. CARGA DE IMÁGENES ANTES DE ARMAR EL PDF
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

    // 2. CREACIÓN DEL PDF
    final pdf = pw.Document();
    final totales = _calcularTotales();

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.letter, // FORMATO VERTICAL
      margin: const pw.EdgeInsets.all(20),
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
      buildBackground:
          (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: colorBackground),
          ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header:
            (context) =>
                _buildHeader(financieraLogo, finoraLogo), // Pasamos los logos
        footer: (context) => _buildFooter(context),
        build:
            (context) => [
              // Títulos de columnas
              _buildColumnLegend(),
              pw.SizedBox(height: 10),

              // Iteramos sobre los créditos
              ...listaCreditos.asMap().entries.map((entry) {
                return pw.Wrap(
                  children: [_buildExpandedCard(entry.value, entry.key + 1)],
                );
              }),
              pw.SizedBox(height: 20),
              _buildTotalsBar(totales),
            ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/reporte_creditos_completo.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }

  // ==========================================
  //      COMPONENTES VISUALES
  // ==========================================

  // --- NUEVO HEADER ESTILO "REPORTE CONTABLE" ---
  pw.Widget _buildHeader(Uint8List? financieraLogo, Uint8List finoraLogo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // --- LOGOS ---
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
              pw.SizedBox(
                width: 120,
                height: 40,
              ), // Espacio por si no hay logo de financiera
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
          'Reporte de Créditos Activos',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: colorPrimary,
          ),
        ),

        pw.SizedBox(height: 10),

        // --- ASESOR ---
        if (nombreUsuario.isNotEmpty && nombreUsuario != 'Todos los usuarios')
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              'Asesor: ${_limpiarTexto(nombreUsuario)}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),

        pw.SizedBox(height: 5),

        // --- FECHAS ---
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Estado: Créditos Activos', // Opcionalmente puedes poner un período si lo tuvieras
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

  pw.Widget _buildColumnLegend() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: colorHeaderBg,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text("Nombre / Asesor", style: _legendStyle()),
          ),
          pw.Expanded(flex: 2, child: pw.Text("Tipo", style: _legendStyle())),
          pw.Expanded(
            flex: 3,
            child: pw.Text("Progreso", style: _legendStyle()),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              "Pagado",
              style: _legendStyle(),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              "Por Pagar",
              style: _legendStyle(),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              "Mora",
              style: _legendStyle(),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              "Adeudo Total",
              style: _legendStyle(),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              "Estado",
              style: _legendStyle(),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  pw.TextStyle _legendStyle() => pw.TextStyle(
    fontSize: 6,
    fontWeight: pw.FontWeight.bold,
    color: colorPrimary,
  );

  // --- LA TARJETA PRINCIPAL (ESTILO EXPANDIDO) ---
  pw.Widget _buildExpandedCard(ReporteCreditoActivo credito, int index) {
    // Cálculos Financieros
    final double restanteCredito = credito.montoMasInteres - credito.totalPagos;
    final double moraGenerada = credito.estadoCredito?.acumulado ?? 0.0;
    final double moraPagada = credito.totalMora;
    final double moraRestante = (moraGenerada - moraPagada).clamp(
      0.0,
      double.infinity,
    );
    final double granTotalDeuda = restanteCredito + moraRestante;

    final pagosInfo = _parseRange(credito.numPago, credito.plazo);
    final tiempoInfo = _parseRange(credito.periodoPagoActual, credito.plazo);
    final double porcentajePagos =
        pagosInfo.total > 0
            ? (pagosInfo.current / pagosInfo.total).clamp(0.0, 1.0)
            : 0.0;
    final double porcentajeTiempo =
        tiempoInfo.total > 0
            ? (tiempoInfo.current / tiempoInfo.total).clamp(0.0, 1.0)
            : 0.0;

    // Validar si es semanal, quincenal o mensual para las etiquetas
    String textoPeriodo = "Semanal";
    final String tipoPlazoLower = credito.tipoPlazo.toLowerCase();
    if (tipoPlazoLower.contains('quincenal')) {
      textoPeriodo = "Quincenal";
    } else if (tipoPlazoLower.contains('mensual')) {
      textoPeriodo = "Mensual";
    } else if (tipoPlazoLower.contains('catorcenal')) {
      textoPeriodo = "Catorcenal";
    } else if (tipoPlazoLower.contains('diario')) {
      textoPeriodo = "Diario";
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        color: colorCard,
        borderRadius: pw.BorderRadius.circular(6),
        boxShadow: const [
          pw.BoxShadow(
            color: PdfColors.grey300,
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: pw.Column(
        children: [
          // 1. ENCABEZADO DE LA TARJETA
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Col 1: Nombre
                pw.Expanded(
                  flex: 3,
                  child: pw.Row(
                    children: [
                      _buildIndexCircle(index),
                      pw.SizedBox(width: 4),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              _limpiarTexto(credito.nombreGrupo),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 6,
                                color: colorTextPrimary,
                              ),
                            ),
                            pw.Text(
                              '${_limpiarTexto(credito.asesor)} - ${credito.ti_mensual}%',
                              style: const pw.TextStyle(
                                fontSize: 6,
                                color: colorTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Col 2: Tipo
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _limpiarTexto(credito.tipoPlazo),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 7,
                          color: colorTextPrimary,
                        ),
                      ),
                      pw.Text(
                        _limpiarTexto(credito.tipo),
                        style: const pw.TextStyle(
                          fontSize: 6,
                          color: colorTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Col 3: Progreso
                pw.Expanded(
                  flex: 3,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 6),
                    child: _buildProgressBar(
                      pagosInfo.current,
                      tiempoInfo.current,
                      pagosInfo.total,
                      porcentajePagos,
                      porcentajeTiempo,
                    ),
                  ),
                ),

                // Col 4, 5, 6, 7: VALORES FINANCIEROS
                _buildFinancialColumn(
                  "de ${currencyFormat.format(credito.montoMasInteres)}",
                  credito.totalPagos,
                  colorGreen,
                ),
                _buildFinancialColumn(
                  "Restante Cr.",
                  restanteCredito,
                  colorTextPrimary,
                ),
                _buildFinancialColumn(
                  "Gen: ${currencyFormat.format(moraGenerada)}",
                  moraRestante,
                  colorOrange,
                ),
                _buildFinancialColumn(
                  "Total Final",
                  granTotalDeuda,
                  colorRed,
                  isBold: true,
                ),

                // Col 8: Estado
                pw.Expanded(
                  flex: 2,
                  child: pw.Center(
                    child: _buildStatusChip(credito.estadoPeriodo),
                  ),
                ),
              ],
            ),
          ),

          // LÍNEA DIVISORIA
          pw.Divider(height: 1, color: PdfColors.grey200),

          // 2. CONTENIDO EXPANDIDO (Detalles)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFAFAFA),
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(6),
                bottomRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Detalles Financieros"),
                pw.SizedBox(height: 6),
                pw.Wrap(
                  spacing: 0,
                  runSpacing: 8,
                  children: [
                    _buildInfoBox("M. Autorizado", credito.montoTotal),
                    _buildInfoBox(
                      "Garantia (${credito.porcentajeGarantia})",
                      credito.montoGarantia,
                    ),
                    _buildInfoBox("M. Desembolsado", credito.montoDesembolsado),
                    _buildInfoBox("Interes Total", credito.interesTotal),
                    _buildInfoBox("Total a Pagar", credito.montoMasInteres),
                    _buildInfoBox("Pago $textoPeriodo", credito.pagoCuota),
                    _buildInfoBox(
                      "Capital $textoPeriodo",
                      credito.semanalCapital,
                    ),
                    _buildInfoBox(
                      "Interes $textoPeriodo",
                      credito.semanalInteres,
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),

                _buildSectionTitle(
                  "Historial de Pagos (${_limpiarTexto(credito.fechasInicioFin)})",
                ),
                pw.SizedBox(height: 6),
                _buildPaymentHistory(credito.fechas),

                pw.SizedBox(height: 12),

                _buildSectionTitle(
                  "Integrantes del Grupo (${credito.clientes.length})",
                ),
                pw.SizedBox(height: 6),
                _buildMembersTable(credito.clientes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-COMPONENTES ---

  pw.Widget _buildSectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(width: 3, height: 10, color: colorPrimary),
        pw.SizedBox(width: 6),
        pw.Text(
          _limpiarTexto(title),
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: colorTextPrimary,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoBox(String label, double value) {
    return pw.SizedBox(
      width: 60,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _limpiarTexto(label),
            style: const pw.TextStyle(fontSize: 6, color: colorTextSecondary),
            maxLines: 1,
          ),
          pw.Text(
            currencyFormat.format(value),
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: colorTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentHistory(List<FechaPagoCredito> fechas) {
    return pw.Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          fechas.map((fecha) {
            PdfColor color;
            String label = fecha.numPago.toString();
            String lower = _limpiarTexto(fecha.estado.toLowerCase());
            String statusShort = "";

            if (lower.contains('desembolso')) {
              color = PdfColors.blue;
              label = "D";
              statusShort = "DES";
            } else if (lower.contains('pagado') || lower.contains('garantia')) {
              color = colorGreen;
              statusShort = "OK";
            } else if (lower.contains('atraso')) {
              color = colorRed;
              statusShort = "ATR";
            } else if (lower.contains('pendiente')) {
              color = colorOrange;
              statusShort = "PEN";
            } else {
              color = PdfColors.grey;
              statusShort = "-";
            }

            String dateStr = "";
            try {
              final d = DateTime.parse(fecha.fechaPago);
              dateStr = "${d.day}/${d.month}";
            } catch (_) {}

            return pw.Column(
              children: [
                pw.Container(
                  width: 16,
                  height: 16,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: color,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Text(
                    label,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  dateStr,
                  style: const pw.TextStyle(
                    fontSize: 5,
                    color: colorTextSecondary,
                  ),
                ),
                pw.Text(
                  statusShort,
                  style: pw.TextStyle(
                    fontSize: 5,
                    color: color,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  pw.Widget _buildMembersTable(List<ClienteMontoInd> clientes) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            color: PdfColors.grey200,
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text("Nombre", style: _tableHeaderStyle()),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text("Cargo", style: _tableHeaderStyle()),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    "Capital",
                    style: _tableHeaderStyle(),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    "Total",
                    style: _tableHeaderStyle(),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          ...clientes.map((cliente) {
            final isEven = clientes.indexOf(cliente) % 2 == 0;
            return pw.Container(
              color: isEven ? PdfColors.white : PdfColor.fromInt(0xFFFAFAFA),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 3,
                horizontal: 6,
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      _limpiarTexto(cliente.nombreCompleto),
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: colorTextPrimary,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      _limpiarTexto(
                        cliente.cargo.isEmpty ? 'Miembro' : cliente.cargo,
                      ),
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: colorTextSecondary,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      currencyFormat.format(cliente.capitalIndividual),
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: colorTextPrimary,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      currencyFormat.format(cliente.total),
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: colorTextPrimary,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.TextStyle _tableHeaderStyle() {
    return pw.TextStyle(
      fontSize: 7,
      fontWeight: pw.FontWeight.bold,
      color: colorTextPrimary,
    );
  }

  pw.Widget _buildIndexCircle(int index) {
    return pw.Container(
      width: 18,
      height: 18,
      alignment: pw.Alignment.center,
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE3F2FD),
        shape: pw.BoxShape.circle,
      ),
      child: pw.Text(
        "$index",
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: colorPrimary,
        ),
      ),
    );
  }

  pw.Widget _buildProgressBar(
    int pagos,
    int tiempo,
    int total,
    double pPagos,
    double pTiempo,
  ) {
    bool hayAtraso = tiempo > pagos;
    int atraso = tiempo - pagos;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "Pag: $pagos/$total",
              style: const pw.TextStyle(fontSize: 6, color: colorGreen),
            ),
            pw.Text(
              "Sem: $tiempo/$total",
              style: const pw.TextStyle(fontSize: 6, color: colorBarTime),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Container(
          height: 4,
          width: double.infinity,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(2),
          ),
          child: pw.Stack(
            children: [
              if (pTiempo > 0.01)
                pw.Container(
                  width: 60 * pTiempo,
                  height: 4,
                  color: colorBarTime,
                ),
              if (pPagos > 0.01)
                pw.Container(width: 60 * pPagos, height: 4, color: colorGreen),
            ],
          ),
        ),
        if (hayAtraso) ...[
          pw.SizedBox(height: 1),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Atraso de $atraso pagos",
              style: pw.TextStyle(
                fontSize: 5,
                color: colorRed,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildFinancialColumn(
    String label,
    double value,
    PdfColor color, {
    bool isBold = false,
  }) {
    return pw.Expanded(
      flex: 2,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            currencyFormat.format(value),
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            _limpiarTexto(label),
            style: const pw.TextStyle(fontSize: 5, color: colorTextSecondary),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatusChip(String status) {
    PdfColor bg = PdfColors.blue50;
    PdfColor txt = PdfColors.blue700;
    String l = _limpiarTexto(status.toLowerCase());
    if (l.contains('pagado') || l.contains('garantia')) {
      bg = PdfColor.fromInt(0xFFE8F5E9);
      txt = PdfColor.fromInt(0xFF2E7D32);
    } else if (l.contains('atraso')) {
      bg = PdfColor.fromInt(0xFFFFEBEE);
      txt = PdfColor.fromInt(0xFFC62828);
    } else if (l.contains('pendiente')) {
      bg = PdfColor.fromInt(0xFFFFF3E0);
      txt = PdfColor.fromInt(0xFFEF6C00);
    }
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        _limpiarTexto(status),
        style: pw.TextStyle(
          color: txt,
          fontSize: 5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Pagina ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _buildTotalsBar(Map<String, double> totales) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: colorCard,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: colorPrimary, width: 1.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "TOTALES (${listaCreditos.length})",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: colorPrimary,
              fontSize: 10,
            ),
          ),
          pw.Row(
            children: [
              _buildTotalItem("Pagado", totales['pagado']!, colorGreen),
              pw.SizedBox(width: 10),
              _buildTotalItem(
                "Cr. Rest.",
                totales['restante']!,
                colorTextPrimary,
              ),
              pw.SizedBox(width: 10),
              _buildTotalItem("Mora", totales['mora']!, colorOrange),
              pw.SizedBox(width: 10),
              pw.Container(width: 1, height: 16, color: PdfColors.grey300),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "ADEUDO TOTAL",
                    style: pw.TextStyle(
                      fontSize: 6,
                      color: colorTextSecondary,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    currencyFormat.format(totales['total']),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: colorRed,
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

  pw.Widget _buildTotalItem(String label, double value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          _limpiarTexto(label),
          style: pw.TextStyle(
            fontSize: 6,
            color: colorTextSecondary,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          currencyFormat.format(value),
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  ({int current, int total}) _parseRange(String rangeStr, int plazoDefault) {
    try {
      final parts = rangeStr.split('-').map((e) => e.trim()).toList();
      if (parts.length >= 2) {
        return (
          current: int.tryParse(parts[0]) ?? 0,
          total: int.tryParse(parts[1]) ?? 1,
        );
      }
      return (
        current: int.tryParse(rangeStr) ?? 0,
        total: plazoDefault > 0 ? plazoDefault : 1,
      );
    } catch (e) {
      return (current: 0, total: 1);
    }
  }
}
