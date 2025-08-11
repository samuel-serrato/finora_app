// lib/screens/reporteContable.dart o donde lo tengas

import 'package:finora_app/helpers/responsive_helpers.dart';
import 'package:finora_app/models/reporte_contable.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ReporteContableWidget extends StatelessWidget {
  final ReporteContableData reporteData;
  final NumberFormat currencyFormat;
  final ScrollController? verticalScrollController;
  final ScrollController? horizontalScrollController;

  const ReporteContableWidget({
    super.key,
    required this.reporteData,
    required this.currencyFormat,
    this.verticalScrollController,
    this.horizontalScrollController,
  });

  static const Color primaryColor = Color(0xFF5162F6);

  @override
  Widget build(BuildContext context) {
    return context.isMobile
        ? _buildMobileLayout(context)
        : _buildDesktopLayout(context);
  }

  //============================================================================
  // === VISTA DE ESCRITORIO (SIN CAMBIOS, USADA COMO REFERENCIA) ==============
  //============================================================================

  Widget _buildDesktopLayout(BuildContext context) {
    // ... Tu código de escritorio se mantiene sin cambios ...
    // ... Lo pego al final para mantener la integridad del archivo ...
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopHeader(context),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Expanded(child: _buildDesktopGruposList(context)),
                        const SizedBox(height: 8),
                        _buildDesktopTotalesCard(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... Todos los demás widgets de escritorio ...

  //============================================================================
  // === VISTA MÓVIL (CORREGIDA PARA PARIDAD 1:1) ==============================
  //============================================================================

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Provider.of<ThemeProvider>(context).colors.backgroundPrimary,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMobileHeader(context),
          const SizedBox(height: 16),
          if (reporteData.listaGrupos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48.0),
              child: Center(child: Text('No hay grupos para mostrar')),
            )
          else
            Column(
              children:
                  reporteData.listaGrupos
                      .asMap()
                      .entries
                      .map(
                        (entry) => _buildMobileGrupoCard(
                          context,
                          entry.value,
                          entry.key,
                        ),
                      )
                      .toList(),
            ),
          const SizedBox(height: 16),
          _buildMobileTotalsSummary(context),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calculate_rounded,
                color: primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Reporte Contable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMobileInfoRow('Período', reporteData.fechaSemana, context),
          _buildMobileInfoRow('Generado', reporteData.fechaActual, context),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(String label, String value, BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileGrupoCard(
    BuildContext context,
    ReporteContableGrupo grupo,
    int index,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Text(
            (index + 1).toString(),
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          grupo.grupos,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Folio: ${grupo.folio} • ${grupo.tipopago}',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildMobileDetailSection(
                  context,
                  'Información del Crédito',
                  Icons.attach_money,
                  _buildMobileFinancialDetails(context, grupo),
                ),
                const SizedBox(height: 12),
                _buildMobileDetailSection(
                  context,
                  'Clientes (${grupo.clientes.length})',
                  Icons.people,
                  _buildMobileClientesList(context, grupo),
                ),
                const SizedBox(height: 12),
                // === CORRECCIÓN: Esta sección ahora tiene toda la lógica de escritorio ===
                _buildMobileDetailSection(
                  context,
                  'Depósitos',
                  Icons.account_balance_wallet,
                  _buildMobileDepositosList(context, grupo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDetailSection(
    BuildContext context,
    String title,
    IconData icon,
    Widget content,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.backgroundCardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildMobileFinancialDetails(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final periodoText = grupo.tipopago == "SEMANAL" ? "Semanal" : "Quincenal";
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileFinancialItem(
                    context,
                    'Garantía',
                    grupo.garantia,
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Monto Solicitado',
                    currencyFormat.format(grupo.montoSolicitado),
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Interés Total',
                    currencyFormat.format(grupo.interesCredito),
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Monto Ficha',
                    currencyFormat.format(grupo.montoficha),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileFinancialItem(
                    context,
                    'Tasa',
                    '${grupo.tazaInteres}%',
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Monto Desembolsado',
                    currencyFormat.format(grupo.montoDesembolsado),
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Monto a Recuperar',
                    currencyFormat.format(grupo.montoARecuperar),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                context,
                'Capital $periodoText',
                currencyFormat.format(grupo.capitalsemanal),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileStatCard(
                context,
                'Interés $periodoText',
                currencyFormat.format(grupo.interessemanal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                context,
                'Moratorios Generados',
                currencyFormat.format(grupo.moratorios.moratoriosAPagar ?? 0.0),
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileStatCard(
                context,
                'Moratorios Pagados',
                currencyFormat.format(grupo.pagoficha.sumaMoratorio ?? 0.0),
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFinancialItem(
    BuildContext context,
    String label,
    String value,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatCard(
    BuildContext context,
    String label,
    String value, {
    Color color = primaryColor,
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(8.0),
      ),
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileClientesList(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    double totalCapital = grupo.clientes.fold(
      0,
      (sum, item) => sum + item.periodoCapital,
    );
    double totalInteres = grupo.clientes.fold(
      0,
      (sum, item) => sum + item.periodoInteres,
    );
    double totalGeneral = totalCapital + totalInteres;

    return Column(
      children: [
        ...grupo.clientes.map(
          (cliente) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cliente.nombreCompleto,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      currencyFormat.format(cliente.capitalMasInteres),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Cap: ${currencyFormat.format(cliente.periodoCapital)} • Int: ${currencyFormat.format(cliente.periodoInteres)}',
                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Totales del Grupo',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              currencyFormat.format(totalGeneral),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // === CORRECCIÓN PRINCIPAL: Esta sección ahora refleja 1:1 la lógica del escritorio ===
  Widget _buildMobileDepositosList(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final pagoficha = grupo.pagoficha;
    final colors = Provider.of<ThemeProvider>(context).colors;

    if (pagoficha.depositos.isEmpty && pagoficha.favorUtilizado == 0) {
      return Center(
        child: Text(
          "Sin depósitos registrados.",
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMobileInfoRow(
          'Fecha Programada',
          _formatDateSafe(pagoficha.fechasPago),
          context,
        ),
        const SizedBox(height: 12),

        // El bucle que muestra los depósitos se mantiene igual
        ...pagoficha.depositos
            .map(
              (deposito) =>
              // _buildMobileStandardDepositCard(context, deposito, pagoficha),
              // --- AHORA ---
              _buildMobileCompactDepositRow(context, deposito),
            )
            .toList(),

        // --- NUEVO: AÑADIMOS LA TARJETA RESUMEN DEL SALDO A FAVOR AQUÍ ---
        // Solo la mostramos si hay un saldo a favor que reportar.
        if (pagoficha.saldofavor > 0)
          _buildSaldoFavorSummaryCard(
            context,
            pagoficha,
          ), // Widget que crearemos

        if (pagoficha.favorUtilizado > 0)
          _buildMobileFavorUtilizadoCard(context, pagoficha.favorUtilizado),

        const Divider(height: 20),
        if (pagoficha.favorUtilizado > 0)
          _buildMobileFavorUtilizadoCard(context, pagoficha.favorUtilizado),
        const Divider(height: 20),
        _buildMobileDetailRow(
          context,
          'Total Depósitos',
          currencyFormat.format(pagoficha.sumaDeposito),
          valueColor: primaryColor,
        ),
        _buildMobileDetailRow(
          context,
          'Restante Ficha',
          currencyFormat.format(grupo.restanteFicha),
          valueColor: Colors.orange.shade700,
        ),
        const Divider(height: 16),
        _buildMobileDetailRow(
          context,
          'Saldo Global Crédito',
          currencyFormat.format(grupo.saldoGlobal),
        ),
        _buildMobileDetailRow(
          context,
          'Restante Global Crédito',
          currencyFormat.format(grupo.restanteGlobal),
        ),
      ],
    );
  }

  // --- Pega este nuevo widget dentro de tu clase ReporteContableWidget ---

  Widget _buildSaldoFavorSummaryCard(
    BuildContext context,
    Pagoficha pagoficha,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    // Lógica para determinar qué mostrar
    String title;
    String primaryText;
    String? secondaryText;
    String tooltipMessage;

    if (pagoficha.utilizadoPago == 'Si') {
      title = 'Saldo a Favor Utilizado';
      primaryText = currencyFormat.format(pagoficha.saldofavor);
      secondaryText = '(Usado en otro pago)';
      tooltipMessage =
          'Un saldo a favor de ${currencyFormat.format(pagoficha.saldofavor)} generado en este pago fue utilizado completamente en otro.';
    } else if (pagoficha.saldoUtilizado > 0) {
      title = 'Saldo a Favor Disponible';
      primaryText = currencyFormat.format(pagoficha.saldoDisponible);
      secondaryText =
          '(de ${currencyFormat.format(pagoficha.saldofavor)} total)';
      tooltipMessage =
          'De un saldo total de ${currencyFormat.format(pagoficha.saldofavor)}, se usaron ${currencyFormat.format(pagoficha.saldoUtilizado)} en otro pago.';
    } else {
      title = 'Saldo a Favor Generado';
      primaryText = currencyFormat.format(pagoficha.saldofavor);
      secondaryText = '(Disponible)';
      tooltipMessage =
          'Se generó un saldo a favor de ${currencyFormat.format(pagoficha.saldofavor)} en este pago, que está disponible para usarse.';
    }

    return Tooltip(
      message: tooltipMessage,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.backgroundCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.blue.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (secondaryText != null)
                    Text(
                      secondaryText,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              primaryText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                decoration:
                    (pagoficha.utilizadoPago == 'Si')
                        ? TextDecoration.lineThrough
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === NUEVO WIDGET: Tarjeta para un depósito estándar, con toda la info del desktop ===
  Widget _buildMobileStandardDepositCard(
    BuildContext context,
    Deposito deposito,
    Pagoficha pagoficha,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final isGarantia = deposito.garantia == "Si";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isGarantia
                  ? const Color(0xFFE53888)
                  : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Text(
              'Fecha depósito: ${_formatDateSafe(deposito.fechaDeposito)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMobileDepositoDetail(
                      context,
                      'Depósito',
                      deposito.deposito,
                      Icons.arrow_downward,
                    ),
                    //_buildMobileSaldoFavorInCard(context, pagoficha),
                    _buildMobileDepositoDetail(
                      context,
                      'Moratorio',
                      deposito.pagoMoratorio,
                      Icons.warning,
                    ),
                  ],
                ),
                if (isGarantia)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Pago con garantía',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFE53888),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === NUEVO WIDGET: Tarjeta para un abono con Saldo a Favor, imitando al desktop ===
  Widget _buildMobileFavorUtilizadoCard(
    BuildContext context,
    double favorUtilizado,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: const Text(
              'Abono con Saldo a Favor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: _buildMobileDetailRow(
              context,
              "Monto utilizado:",
              currencyFormat.format(favorUtilizado),
              valueColor: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // === NUEVO WIDGET: Muestra el "Saldo a Favor" generado dentro de la tarjeta de depósito ===
  Widget _buildMobileSaldoFavorInCard(
    BuildContext context,
    Pagoficha pagoficha,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    Widget valueDisplay;
    String? tooltipMessage;

    if (pagoficha.saldofavor == 0) {
      valueDisplay = Text(
        currencyFormat.format(0.0),
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
          color: colors.textPrimary,
        ),
      );
    } else if (pagoficha.utilizadoPago == 'Si') {
      tooltipMessage =
          'Saldo de ${currencyFormat.format(pagoficha.saldofavor)} utilizado completamente en otro pago.';
      valueDisplay = Text(
        currencyFormat.format(pagoficha.saldofavor),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colors.textSecondary,
          decoration: TextDecoration.lineThrough,
        ),
      );
    } else if (pagoficha.saldoUtilizado > 0) {
      tooltipMessage =
          'Original: ${currencyFormat.format(pagoficha.saldofavor)}\nUtilizado: ${currencyFormat.format(pagoficha.saldoUtilizado)}';
      valueDisplay = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            currencyFormat.format(pagoficha.saldoDisponible),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: colors.textPrimary,
            ),
          ),
          Text(
            '(de ${currencyFormat.format(pagoficha.saldofavor)})',
            style: TextStyle(fontSize: 9, color: colors.textSecondary),
          ),
        ],
      );
    } else {
      valueDisplay = Text(
        currencyFormat.format(pagoficha.saldofavor),
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
          color: colors.textPrimary,
        ),
      );
    }

    Widget content = Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 10,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 3),
            Text(
              'Saldo Favor',
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
          ],
        ),
        valueDisplay,
      ],
    );

    if (tooltipMessage != null) {
      return Tooltip(message: tooltipMessage, child: content);
    }
    return content;
  }

  // === NUEVO WIDGET: Muestra una pieza de información dentro de la tarjeta de depósito ===
  Widget _buildMobileDepositoDetail(
    BuildContext context,
    String label,
    double value,
    IconData icon,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: colors.textSecondary),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
          ],
        ),
        Text(
          currencyFormat.format(value),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTotalsSummary(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Resumen Financiero Total',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildMobileDetailRow(
            context,
            'Capital Total',
            currencyFormat.format(reporteData.totalCapital),
          ),
          _buildMobileDetailRow(
            context,
            'Interés Total',
            currencyFormat.format(reporteData.totalInteres),
          ),
          const Divider(height: 16),
          _buildMobileDetailRow(
            context,
            'Monto Total Fichas',
            currencyFormat.format(reporteData.totalFicha),
          ),
          _buildMobileDetailRow(
            context,
            'Pago Total Fichas',
            currencyFormat.format(reporteData.totalPagoficha),
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'S. Favor Disponible',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ),
              Tooltip(
                message:
                    'Total generado históricamente: ${currencyFormat.format(reporteData.totalSaldoFavor)}',
                child: Row(
                  children: [
                    Text(
                      currencyFormat.format(reporteData.totalSaldoDisponible),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildMobileDetailRow(
            context,
            'Moratorios',
            currencyFormat.format(reporteData.saldoMoratorio),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMobileTotalItem(
                      'Total Ideal',
                      reporteData.totalTotal,
                    ),
                    _buildMobileTotalItem('Diferencia', reporteData.restante),
                  ],
                ),
                const Divider(color: Colors.white30, height: 20),
                _buildMobileTotalItem(
                  'Total Bruto',
                  reporteData.sumaTotalCapMoraFav,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTotalItem(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(value),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatDateSafe(String dateString) {
    try {
      if (dateString.isEmpty) return 'N/A';
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  //============================================================================
  // === CÓDIGO DE DESKTOP PEGADO PARA INTEGRIDAD ===============================
  //============================================================================

  Widget _buildDesktopHeader(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.bar_chart_rounded, color: primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          'Período: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          reporteData.fechaSemana,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: isDarkMode ? Colors.grey[300] : Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Generado: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          reporteData.fechaActual,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: isDarkMode ? Colors.grey[300] : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTotalesCard(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 1,
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Totales',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: horizontalScrollController,
                  child: Row(
                    children: [
                      Container(
                        height: 24,
                        width: 1,
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        margin: const EdgeInsets.only(right: 16),
                      ),
                      _buildDesktopSummaryItem(
                        context,
                        'Capital Total',
                        reporteData.totalCapital,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Interés Total',
                        reporteData.totalInteres,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Monto Fichas',
                        reporteData.totalFicha,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Pago Fichas',
                        reporteData.totalPagoficha,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSaldoFavorTotalItem(context),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Moratorios',
                        reporteData.saldoMoratorio,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Total Ideal',
                        reporteData.totalTotal,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Diferencia',
                        reporteData.restante,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Total Bruto',
                        reporteData.sumaTotalCapMoraFav,
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSaldoFavorTotalItem(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Row(
      children: [
        _buildDesktopSummaryItem(
          context,
          'S. Favor Disp.',
          reporteData.totalSaldoDisponible,
        ),
        const SizedBox(width: 6),
        Tooltip(
          message:
              'Total generado históricamente: ${currencyFormat.format(reporteData.totalSaldoFavor)}',
          child: MouseRegion(
            cursor: SystemMouseCursors.help,
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSummaryItem(
    BuildContext context,
    String label,
    double value, {
    bool isPrimary = false,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color:
                isPrimary
                    ? primaryColor
                    : (isDarkMode ? Colors.grey[600] : Colors.grey[300]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              currencyFormat.format(value),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color:
                    isPrimary
                        ? primaryColor
                        : (isDarkMode ? Colors.grey[300] : Colors.grey[800]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopGruposList(BuildContext context) {
    if (reporteData.listaGrupos.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar'));
    }
    return ListView.builder(
      controller: verticalScrollController,
      itemCount: reporteData.listaGrupos.length,
      itemBuilder: (context, index) {
        final grupo = reporteData.listaGrupos[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildDesktopGrupoCard(context, grupo),
        );
      },
    );
  }

  Widget _buildDesktopGrupoCard(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        grupo.grupos,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(Folio: ${grupo.folio})',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildDesktopInfoText(context, 'Pago: ${grupo.tipopago}'),
                    _buildDesktopInfoText(context, 'Plazo: ${grupo.plazo}'),
                    _buildDesktopInfoText(
                      context,
                      'Periodo Pago: ${grupo.pagoPeriodo}',
                    ),
                  ],
                ),
              ],
            ),
            Divider(
              height: 16,
              thickness: 0.5,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildDesktopClientesSection(grupo, context)),
                const SizedBox(width: 20),
                SizedBox(
                  width: 300,
                  child: _buildDesktopFinancialColumn(context, grupo),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 300,
                  child: _buildDesktopDepositosSection(
                    context,
                    grupo.pagoficha,
                    grupo.restanteFicha,
                    grupo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopFinancialColumn(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.attach_money, size: 14, color: primaryColor),
            SizedBox(width: 6),
            Text(
              'Información del Crédito',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildDesktopFinancialInfoText(
                      context,
                      'Garantía',
                      grupo.garantia,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Tasa',
                      grupo.tazaInteres,
                      isPercentage: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Monto Solicitado',
                      grupo.montoSolicitado,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Monto Desembolsado',
                      grupo.montoDesembolsado,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Interés Total',
                      grupo.interesCredito,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Monto a Recuperar',
                      grupo.montoARecuperar,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDesktopFinancialInfo(
                context,
                '${grupo.tipopago == "SEMANAL" ? "Capital Semanal" : "Capital Quincenal"}',
                grupo.capitalsemanal,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildDesktopFinancialInfo(
                context,
                '${grupo.tipopago == "SEMANAL" ? "Interés Semanal" : "Interés Quincenal"}',
                grupo.interessemanal,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildDesktopFinancialInfo(
                context,
                'Monto Ficha',
                grupo.montoficha,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDesktopFinancialInfo(
                context,
                'Moratorios Generados',
                grupo.moratorios.moratoriosAPagar ?? 0.0,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildDesktopFinancialInfo(
                context,
                'Moratorios Pagados',
                grupo.pagoficha.sumaMoratorio ?? 0.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopFinancialInfoCompact(
    BuildContext context,
    String label,
    double value, {
    bool isPercentage = false,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          '${currencyFormat.format(value)}${isPercentage ? '%' : ''}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDesktopFinancialInfoText(
    BuildContext context,
    String label,
    String value,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDesktopInfoText(BuildContext context, String text) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: isDarkMode ? Colors.grey[300] : Colors.grey[900],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDesktopFinancialInfo(
    BuildContext context,
    String label,
    double value,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            currencyFormat.format(value),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopClientesSection(
    ReporteContableGrupo grupo,
    BuildContext context,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    double totalCapital = grupo.clientes.fold(
      0,
      (sum, item) => sum + item.periodoCapital,
    );
    double totalInteres = grupo.clientes.fold(
      0,
      (sum, item) => sum + item.periodoInteres,
    );
    double totalGeneral = grupo.clientes.fold(
      0,
      (sum, item) => sum + item.capitalMasInteres,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people, size: 14, color: primaryColor),
            const SizedBox(width: 6),
            Text(
              'Clientes (${grupo.clientes.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey[300]!),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Nombre Cliente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Capital',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Interés',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Capital + Interés',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              ...grupo.clientes.map(
                (cliente) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        cliente.nombreCompleto,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        currencyFormat.format(cliente.periodoCapital),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        currencyFormat.format(cliente.periodoInteres),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        currencyFormat.format(cliente.capitalMasInteres),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TableRow(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(81, 98, 246, 0.1),
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Totales',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      currencyFormat.format(totalCapital),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      currencyFormat.format(totalInteres),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      currencyFormat.format(totalGeneral),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Pega este nuevo widget para ESCRITORIO ---

  Widget _buildDesktopCompactDepositRow(
    BuildContext context,
    Deposito deposito,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final isGarantia = deposito.garantia == "Si";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Columna 1: Fecha
          SizedBox(
            width: 90,
            child: Text(
              _formatDateSafe(deposito.fechaDeposito),
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),

          // Columna 2: Monto del depósito y tooltip de garantía
          Expanded(
            child: Row(
              children: [
                Text(
                  currencyFormat.format(deposito.deposito),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (isGarantia)
                  Tooltip(
                    message: "Pago con garantía",
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: Icon(
                        Icons.shield,
                        size: 12,
                        color: const Color(0xFFE53888),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Columna 3: Moratorio
          SizedBox(
            width: 80,
            child: Text(
              currencyFormat.format(deposito.pagoMoratorio),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDepositosSection(
    BuildContext context,
    Pagoficha pagoficha,
    double restanteFicha,
    ReporteContableGrupo grupo,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, size: 14, color: primaryColor),
                SizedBox(width: 6),
                Text(
                  'Depósitos',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            Text(
              'Fecha programada: ${_formatDateSafe(pagoficha.fechasPago)}',
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          child:
              pagoficha.depositos.isEmpty && pagoficha.favorUtilizado == 0
                  ? Center(
                    child: Text(
                      'Sin depósitos registrados',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  )
                  : ListView(
                    shrinkWrap: true,
                    children: [
                      ...pagoficha.depositos
                          .map(
                            (deposito) => _buildDesktopStandardDepositCard(
                              context,
                              deposito,
                              pagoficha,
                            ),
                          )
                          .toList(),
                      if (pagoficha.favorUtilizado > 0)
                        _buildDesktopFavorUtilizadoCard(
                          context,
                          pagoficha.favorUtilizado,
                          pagoficha.fechasPago,
                        ),

                    ],
                  ),
        ),
        // --- NUEVO: AÑADIMOS LA FILA ESTÁTICA SI HAY SALDO A FAVOR ---
        if (pagoficha.saldofavor > 0)
          //_buildDesktopSaldoFavorStaticRow(context, pagoficha),
          _buildDesktopSaldoFavorSummaryRow(context, pagoficha),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(top: 6, bottom: 8),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? const Color(0xFF000000).withOpacity(0.3)
                    : primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total depósitos:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
              Text(
                currencyFormat.format(pagoficha.sumaDeposito),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? Colors.orange[900]!.withOpacity(0.2)
                    : Colors.orange[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDarkMode ? Colors.orange[800]! : Colors.orange[200]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Restante ficha:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.orange[300] : Colors.orange[900],
                ),
              ),
              Text(
                currencyFormat.format(restanteFicha),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.orange[300] : Colors.orange[900],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen Global',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Saldo Global',
                      grupo.saldoGlobal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Restante Global',
                      grupo.restanteGlobal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Pega este nuevo widget dentro de tu clase ReporteContableWidget ---

  Widget _buildDesktopSaldoFavorSummaryRow(
    BuildContext context,
    Pagoficha pagoficha,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    // Lógica para determinar el texto y el tooltip
    String title;
    String primaryText;
    String? secondaryText;
    String tooltipMessage;

    if (pagoficha.utilizadoPago == 'Si') {
      title = 'S. Favor (Utilizado)';
      primaryText = currencyFormat.format(pagoficha.saldofavor);
      secondaryText = 'Usado en otro pago.';
      tooltipMessage =
          'Un saldo a favor de ${currencyFormat.format(pagoficha.saldofavor)} generado en este pago fue utilizado completamente en otro.';
    } else if (pagoficha.saldoUtilizado > 0) {
      title = 'S. Favor Disponible';
      primaryText = currencyFormat.format(pagoficha.saldoDisponible);
      secondaryText = 'de ${currencyFormat.format(pagoficha.saldofavor)} total';
      tooltipMessage =
          'De un saldo total de ${currencyFormat.format(pagoficha.saldofavor)}, se usaron ${currencyFormat.format(pagoficha.saldoUtilizado)} en otro pago.';
    } else {
      title = 'S. Favor Generado';
      primaryText = currencyFormat.format(pagoficha.saldofavor);
      secondaryText = 'disponible';
      tooltipMessage =
          'Se generó un saldo a favor de ${currencyFormat.format(pagoficha.saldofavor)} en este pago, que está disponible para usarse.';
    }

    // UI del widget, estilizada para escritorio
    return Tooltip(
      message: tooltipMessage,
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isDarkMode ? Colors.blue[900]!.withOpacity(0.3) : Colors.blue[50],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDarkMode ? Colors.blue[800]! : Colors.blue[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 14,
              color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
                    ),
                  ),
                  if (secondaryText != null)
                    Text(
                      secondaryText,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              primaryText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.blue[200] : Colors.blue[900],
                decoration:
                    (pagoficha.utilizadoPago == 'Si')
                        ? TextDecoration.lineThrough
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Pega este nuevo widget dentro de tu clase ReporteContableWidget ---

  Widget _buildMobileCompactDepositRow(
    BuildContext context,
    Deposito deposito,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final isGarantia = deposito.garantia == "Si";

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.backgroundCard.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isGarantia
                  ? const Color(0xFFE53888)
                  : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Columna Izquierda: Fecha y Monto del depósito
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Depósito: ${_formatDateSafe(deposito.fechaDeposito)}',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    currencyFormat.format(deposito.deposito),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (isGarantia)
                    Tooltip(
                      message: "Pago con garantía",
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Icon(
                          Icons.shield,
                          size: 14,
                          color: const Color(0xFFE53888),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Columna Derecha: Moratorio
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Moratorio',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                currencyFormat.format(deposito.pagoMoratorio),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStandardDepositCard(
    BuildContext context,
    Deposito deposito,
    Pagoficha pagoficha,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF5162F6).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Fecha depósito: ${_formatDateSafe(deposito.fechaDeposito)}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.grey[200] : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDesktopDepositoDetail(
                      context,
                      'Depósito',
                      deposito.deposito,
                      Icons.arrow_downward,
                      depositoCompleto: pagoficha.depositoCompleto,
                    ),
                    //_buildDesktopSaldoFavorDetail(context, pagoficha),
                    _buildDesktopDepositoDetail(
                      context,
                      'Moratorio',
                      deposito.pagoMoratorio,
                      Icons.warning,
                    ),
                  ],
                ),
                if (deposito.garantia == "Si")
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53888),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Garantía',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
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
    );
  }

  Widget _buildDesktopFavorUtilizadoCard(
    BuildContext context,
    double favorUtilizado,
    String fechaOriginal,
  ) {
    return Tooltip(
      message:
          'Este abono se realizó utilizando un saldo a favor de un pago anterior.',
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green.shade600),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: const Align(
                alignment: Alignment.center,
                child: Text(
                  'Abono con Saldo a Favor',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monto utilizado:',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          Provider.of<ThemeProvider>(context).isDarkMode
                              ? const Color(0xFFC0E3C1)
                              : Colors.green.shade800,
                    ),
                  ),
                  Text(
                    currencyFormat.format(favorUtilizado),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          Provider.of<ThemeProvider>(context).isDarkMode
                              ? const Color(0xFFC0E3C1)
                              : Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSaldoFavorDetail(
    BuildContext context,
    Pagoficha pagoficha,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    Widget valueDisplay;
    String? tooltipMessage;

    if (pagoficha.saldofavor == 0) {
      valueDisplay = Text(
        currencyFormat.format(0.0),
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
          color: isDarkMode ? Colors.grey[200] : Colors.black87,
        ),
      );
    } else if (pagoficha.utilizadoPago == 'Si') {
      tooltipMessage =
          'Saldo de ${currencyFormat.format(pagoficha.saldofavor)} utilizado completamente en otro pago.';
      valueDisplay = Text(
        currencyFormat.format(pagoficha.saldofavor),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white54 : Colors.grey[600],
          decoration: TextDecoration.lineThrough,
        ),
      );
    } else if (pagoficha.saldoUtilizado > 0) {
      tooltipMessage =
          'Original: ${currencyFormat.format(pagoficha.saldofavor)}\n'
          'Utilizado: ${currencyFormat.format(pagoficha.saldoUtilizado)}\n'
          'Disponible: ${currencyFormat.format(pagoficha.saldoDisponible)}';
      valueDisplay = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currencyFormat.format(pagoficha.saldoDisponible),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: isDarkMode ? Colors.grey[200] : Colors.black87,
            ),
          ),
          Text(
            '(de ${currencyFormat.format(pagoficha.saldofavor)})',
            style: TextStyle(
              fontSize: 9,
              color: isDarkMode ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      );
    } else {
      valueDisplay = Text(
        currencyFormat.format(pagoficha.saldofavor),
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
          color: isDarkMode ? Colors.grey[200] : Colors.black87,
        ),
      );
    }

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 10,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 3),
            Text(
              'Saldo a Favor',
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        valueDisplay,
      ],
    );

    if (tooltipMessage != null) {
      return Tooltip(
        message: tooltipMessage,
        decoration: BoxDecoration(
          color: const Color(0xFFE53888),
          borderRadius: BorderRadius.circular(12),
        ),
        child: MouseRegion(cursor: SystemMouseCursors.help, child: content),
      );
    }
    return content;
  }

  Widget _buildDesktopDepositoDetail(
    BuildContext context,
    String label,
    double value,
    IconData icon, {
    double? depositoCompleto,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    bool shouldShowIcon = false;
    if (label == 'Depósito' &&
        depositoCompleto != null &&
        depositoCompleto > 0) {
      const double epsilon = 0.01;
      shouldShowIcon = (value - depositoCompleto).abs() > epsilon;
    }

    Widget detailWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 10,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              currencyFormat.format(value),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: isDarkMode ? Colors.grey[200] : Colors.black87,
              ),
            ),
            if (shouldShowIcon)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Icon(
                  Icons.info_outline,
                  size: 12,
                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                ),
              ),
          ],
        ),
      ],
    );

    if (shouldShowIcon) {
      return Tooltip(
        message:
            'Depósito completo: ${currencyFormat.format(depositoCompleto!)}',
        decoration: BoxDecoration(
          color: const Color(0xFFE53888),
          borderRadius: BorderRadius.circular(12),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.help,
          child: detailWidget,
        ),
      );
    }
    return detailWidget;
  }
}
