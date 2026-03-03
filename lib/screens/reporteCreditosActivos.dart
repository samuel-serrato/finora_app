import 'package:finora_app/models/reporte_creditos_activos.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ReporteCreditosActivosWidget extends StatelessWidget {
  final List<ReporteCreditoActivo> listaCreditos;
  final NumberFormat currencyFormat;

  const ReporteCreditosActivosWidget({
    super.key,
    required this.listaCreditos,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    if (listaCreditos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              "No se encontraron créditos activos.",
              style: TextStyle(color: colors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // --- CÁLCULO DE TOTALES GENERALES ---
    double sumaPagado = 0;
    double sumaRestanteCr = 0;
    double sumaMoraRestante = 0;
    double sumaGranTotal = 0;

    for (var c in listaCreditos) {
      final double restCr = c.montoMasInteres - c.totalPagos;
      final double moraGen = c.estadoCredito?.acumulado ?? 0.0;
      final double moraPag = c.totalMora;
      final double moraRestante = (moraGen - moraPag).clamp(0, double.infinity);

      sumaPagado += c.totalPagos;
      sumaRestanteCr += restCr;
      sumaMoraRestante += moraRestante;
      sumaGranTotal += (restCr + moraRestante);
    }

    return Column(
      children: [
        // --- ENCABEZADO DE TABLA (SOLO DESKTOP > 700px) ---
        if (MediaQuery.of(context).size.width > 700)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.brandPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 35), // Espacio para el número de fila
                Expanded(
                  flex: 3,
                  child: _headerText('Nombre / Asesor', colors),
                ),
                Expanded(flex: 1, child: _headerText('Tipo', colors)),
                Expanded(flex: 3, child: _headerText('Progreso', colors)),
                const SizedBox(
                  width: 24,
                ), // <--- AÑADE ESTE WIDGET PARA CREAR UN HUECO
                Expanded(flex: 2, child: _headerText('Pagado', colors)),
                Expanded(flex: 2, child: _headerText('Por Pagar', colors)),
                Expanded(flex: 2, child: _headerText('Mora', colors)),
                Expanded(flex: 2, child: _headerText('Adeudo Total', colors)),
                Expanded(flex: 2, child: _headerText('Estado', colors)),
                const SizedBox(width: 40),
              ],
            ),
          ),

        // --- LISTADO DE CRÉDITOS ---
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: listaCreditos.length,
            itemBuilder: (context, index) {
              return _ReporteCard(
                numeroFila: index + 1,
                credito: listaCreditos[index],
                currencyFormat: currencyFormat,
              );
            },
          ),
        ),

        // --- BARRA DE TOTALES FIJA AL FINAL ---
        _buildTotalsBar(
          context,
          colors,
          sumaPagado,
          sumaRestanteCr,
          sumaMoraRestante,
          sumaGranTotal,
        ),
      ],
    );
  }

  // Widget para la barra de totales
  Widget _buildTotalsBar(
    BuildContext context,
    dynamic colors,
    double pagado,
    double restante,
    double mora,
    double total,
  ) {
    final bool isDesktop = MediaQuery.of(context).size.width > 700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: colors.brandPrimary.withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child:
            isDesktop
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TOTALES (${listaCreditos.length})",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.brandPrimary,
                        fontSize: 14,
                      ),
                    ),
                    _totalItem("Pagado", pagado, Colors.green, currencyFormat),
                    _totalItem(
                      "Crédito Rest.",
                      restante,
                      colors.textPrimary,
                      currencyFormat,
                    ),
                    _totalItem(
                      "Mora Pendiente",
                      mora,
                      Colors.orange,
                      currencyFormat,
                    ),
                    _totalItem(
                      "ADEUDO TOTAL",
                      total,
                      Colors.redAccent,
                      currencyFormat,
                      isBig: true,
                    ),
                  ],
                )
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _totalItem(
                          "Pagado",
                          pagado,
                          Colors.green,
                          currencyFormat,
                        ),
                        _totalItem(
                          "Cr. Rest.",
                          restante,
                          colors.textPrimary,
                          currencyFormat,
                        ),
                        _totalItem("Mora", mora, Colors.orange, currencyFormat),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${listaCreditos.length} Créditos",
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            const Text(
                              "TOTAL: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              currencyFormat.format(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.redAccent,
                              ),
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

  Widget _totalItem(
    String label,
    double value,
    Color color,
    NumberFormat format, {
    bool isBig = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          format.format(value),
          style: TextStyle(
            fontSize: isBig ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _headerText(String text, dynamic colors) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: colors.brandPrimary,
        fontSize: 12,
      ),
    );
  }
}

class _ReporteCard extends StatelessWidget {
  final int numeroFila;
  final ReporteCreditoActivo credito;
  final NumberFormat currencyFormat;

  const _ReporteCard({
    required this.numeroFila,
    required this.credito,
    required this.currencyFormat,
  });

  ({int current, int total}) _parseRange(String rangeStr) {
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
        total: credito.plazo > 0 ? credito.plazo : 1,
      );
    } catch (e) {
      return (current: 0, total: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    final double restanteCredito = credito.montoMasInteres - credito.totalPagos;
    final double moraGenerada = credito.estadoCredito?.acumulado ?? 0.0;
    final double moraPagada = credito.totalMora;
    double moraRestante = (moraGenerada - moraPagada).clamp(
      0.0,
      double.infinity,
    );
    final double granTotalDeuda = restanteCredito + moraRestante;

    final pagosInfo = _parseRange(credito.numPago);
    final tiempoInfo = _parseRange(credito.periodoPagoActual);

    final double porcentajePagos =
        pagosInfo.total > 0
            ? (pagosInfo.current / pagosInfo.total).clamp(0.0, 1.0)
            : 0.0;
    final double porcentajeTiempo =
        tiempoInfo.total > 0
            ? (tiempoInfo.current / tiempoInfo.total).clamp(0.0, 1.0)
            : 0.0;

    // --- NUEVO: Validar periodo para las etiquetas ---
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
    // -------------------------------------------------

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colors.backgroundCard,
      child: ExpansionTile(
        shape: Border.all(color: Colors.transparent),
        tilePadding: const EdgeInsets.only(
          left: 12,
          right: 12,
          top: 8,
          bottom: 8,
        ),
        leading: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: colors.brandPrimary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: colors.brandPrimary.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            "$numeroFila",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.brandPrimary,
            ),
          ),
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth > 700;

            final progressBar = _UnifiedProgressBar(
              pagosText: "${pagosInfo.current}",
              tiempoText: "${tiempoInfo.current}",
              totalText: "${pagosInfo.total}",
              percentPagos: porcentajePagos,
              percentTiempo: porcentajeTiempo,
              colors: colors,
            );

            if (isDesktop) {
              // --- VISTA ESCRITORIO (SIN CAMBIOS) ---
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credito.nombreGrupo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${credito.asesor} • ${credito.ti_mensual}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credito.tipoPlazo,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          credito.tipo,
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: progressBar,
                    ),
                  ),
                  const SizedBox(
                    width: 24,
                  ), // <--- AÑADE EL MISMO SIZEDBOX AQUÍ
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormat.format(credito.totalPagos),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "de ${currencyFormat.format(credito.montoMasInteres)}",
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormat.format(restanteCredito),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "Restante Cr.",
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormat.format(moraRestante),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "Gen: ${currencyFormat.format(moraGenerada)}",
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormat.format(granTotalDeuda),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "Total Final",
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _StatusChip(status: credito.estadoPeriodo),
                  ),
                ],
              );
            } else {
              // --- VISTA MÓVIL (MODIFICADA PARA IGUALAR LA IMAGEN) ---
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: Nombre y Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          credito.nombreGrupo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15, // Un poco más grande para móvil
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(status: credito.estadoPeriodo, isSmall: true),
                    ],
                  ),
                  // Fila 2: Folio y Asesor
                  Text(
                    "${credito.tipoPlazo} • ${credito.asesor} • ${credito.ti_mensual}%",
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  // Fila 3: Barra de Progreso
                  progressBar,
                  const SizedBox(height: 12),

                  // Fila 4: Desglose financiero (3 columnas)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _mobileInfoMini(
                        "Crédito Restante",
                        currencyFormat.format(restanteCredito),
                        colors.textPrimary,
                        align: CrossAxisAlignment.start,
                      ),
                      _mobileInfoMini(
                        "Mora Restante",
                        currencyFormat.format(moraRestante),
                        Colors.orange,
                        align:
                            CrossAxisAlignment
                                .center, // Centrado como en la imagen
                      ),
                      _mobileInfoMini(
                        "Pagado",
                        currencyFormat.format(credito.totalPagos),
                        Colors.green,
                        align: CrossAxisAlignment.end, // Alineado a la derecha
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fila 5: Caja de Adeudo Total
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      /* border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ), */
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Adeudo Total (Crédito + Mora)",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currencyFormat.format(granTotalDeuda),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
        children: [
          // Los hijos se mantienen igual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle("Detalles Financieros", colors),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _InfoBox(
                      "Monto Autorizado",
                      currencyFormat.format(credito.montoTotal),
                      colors,
                    ),
                    _InfoBox(
                      "Garantía (${credito.porcentajeGarantia})",
                      currencyFormat.format(credito.montoGarantia),
                      colors,
                    ),
                    _InfoBox(
                      "Monto Desembolsado",
                      currencyFormat.format(credito.montoDesembolsado),
                      colors,
                    ),
                    _InfoBox(
                      "Interés Total",
                      currencyFormat.format(credito.interesTotal),
                      colors,
                    ),
                    _InfoBox(
                      "Total a Pagar",
                      currencyFormat.format(credito.montoMasInteres),
                      colors,
                    ),
                    // DESPUÉS
                    _InfoBox(
                      "Pago $textoPeriodo",
                      currencyFormat.format(credito.pagoCuota),
                      colors,
                    ),
                    _InfoBox(
                      "Capital $textoPeriodo",
                      currencyFormat.format(credito.semanalCapital),
                      colors,
                    ),
                    _InfoBox(
                      "Interés $textoPeriodo",
                      currencyFormat.format(credito.semanalInteres),
                      colors,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  "Historial de Pagos (${credito.fechasInicioFin})",
                  colors,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        credito.fechas
                            .map((fecha) => _PaymentWeekBadge(fecha: fecha))
                            .toList(),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  "Integrantes del Grupo (${credito.clientes.length})",
                  colors,
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colors.backgroundCardDark,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Nombre",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Cargo",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Capital",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Total a Pagar",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...credito.clientes.map((cliente) {
                        final isEven =
                            credito.clientes.indexOf(cliente) % 2 == 0;
                        return Container(
                          color:
                              isEven
                                  ? Colors.transparent
                                  : Colors.grey.withOpacity(0.05),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  cliente.nombreCompleto,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  cliente.cargo.isEmpty
                                      ? 'Miembro'
                                      : cliente.cargo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  currencyFormat.format(
                                    cliente.capitalIndividual,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textPrimary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  currencyFormat.format(cliente.total),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

  Widget _mobileInfoMini(
    String label,
    String value,
    Color color, {
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// === WIDGETS AUXILIARES (Sin cambios) ===

class _UnifiedProgressBar extends StatelessWidget {
  final String pagosText;
  final String tiempoText;
  final String totalText;
  final double percentPagos;
  final double percentTiempo;
  final dynamic colors;

  const _UnifiedProgressBar({
    required this.pagosText,
    required this.tiempoText,
    required this.totalText,
    required this.percentPagos,
    required this.percentTiempo,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final bool hayAtraso = percentTiempo > percentPagos;
    final Color colorPagos = Colors.green[500]!;
    final Color colorTiempo = const Color(0xFF0D668F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _legendItem("Pagados: $pagosText/$totalText", colorPagos, colors),
            _legendItem("Semana: $tiempoText/$totalText", colorTiempo, colors),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Container(color: colors.backgroundbar),
                FractionallySizedBox(
                  widthFactor: percentTiempo,
                  child: Container(color: colorTiempo),
                ),
                FractionallySizedBox(
                  widthFactor: percentPagos,
                  child: Container(color: colorPagos),
                ),
              ],
            ),
          ),
        ),
        if (hayAtraso)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Atraso de ${int.parse(tiempoText) - int.parse(pagosText)} pagos",
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _legendItem(String text, Color color, dynamic colors) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final bool isSmall;
  const _StatusChip({required this.status, this.isSmall = false});
  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String lower = status.toLowerCase();
    if (lower.contains('pagado') || lower.contains('garantia')) {
      bg = Colors.green.withOpacity(0.1);
      text = Colors.green;
    } else if (lower.contains('atraso')) {
      bg = Colors.red.withOpacity(0.1);
      text = Colors.red;
    } else if (lower.contains('pendiente')) {
      bg = Colors.orange.withOpacity(0.1);
      text = Colors.orange[800]!;
    } else {
      bg = Colors.blue.withOpacity(0.1);
      text = Colors.blue;
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 2 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: isSmall ? 10 : 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final dynamic colors;
  const _SectionTitle(this.title, this.colors);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          color: colors.brandPrimary,
          margin: const EdgeInsets.only(right: 8),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final dynamic colors;
  const _InfoBox(this.label, this.value, this.colors);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentWeekBadge extends StatelessWidget {
  final FechaPagoCredito fecha;
  const _PaymentWeekBadge({required this.fecha});

  @override
  Widget build(BuildContext context) {
    Color color;
    String statusShort; // Variable para las siglas
    String label = fecha.numPago.toString();
    
    // Normalizamos el texto
    String lower = fecha.estado.toLowerCase(); 

    // --- LÓGICA IGUALADA AL PDF ---
    
    if (lower.contains('desembolso')) {
      color = Colors.blue;
      label = "D"; // Caso especial para el círculo
      statusShort = "DES";
    } 
    else if (lower.contains('pagado') || lower.contains('garantia') || lower.contains('liquidado')) {
      color = Colors.green;
      statusShort = "OK";
    } 
    else if (lower.contains('atraso') || lower.contains('mora') || lower.contains('vencido')) {
      color = Colors.red;
      statusShort = "ATR";
    } 
    else if (lower.contains('pendiente')) {
      color = Colors.orange;
      statusShort = "PEND";
    } 
    else if (lower.contains('proximo')) {
      color = Colors.grey;
      statusShort = "PRO";
    } 
    // CASOS ESPECÍFICOS (ABONO, CURSO, ETC.)
    else if (lower.contains('abono') || lower.contains('parcial')) {
      color = Colors.blueGrey;
      statusShort = "ABONO"; 
    }
    else if (lower.contains('curso')) {
      color = Colors.blueGrey;
      statusShort = "CUR"; 
    } 
    else {
      // DEFAULT
      color = Colors.blueGrey;
      statusShort = lower.length > 3 
          ? lower.substring(0, 3).toUpperCase() 
          : lower.toUpperCase();
    }

    // --- FORMATO DE FECHA ---
    String dateStr = "?";
    try {
      final date = DateTime.parse(fecha.fechaPago);
      dateStr = "${date.day}/${date.month}";
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        children: [
          // CÍRCULO CON NÚMERO
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // FECHA
          Text(
            dateStr, 
            style: TextStyle(fontSize: 9, color: Colors.grey[600])
          ),
          // SIGLAS (statusShort)
          Text(
            statusShort,
            style: TextStyle(
              fontSize: statusShort.length > 3 ? 7 : 8, // Ajuste automático si el texto es largo (ej. ABONO)
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}