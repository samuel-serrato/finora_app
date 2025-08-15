// lib/dialog/cliente_detalle_dialog.dart

import 'package:finora_app/models/clientes.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/cliente_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../helpers/responsive_helpers.dart';

class ClienteDetalleDialog extends StatefulWidget {
  final String idCliente;

  const ClienteDetalleDialog({super.key, required this.idCliente});

  @override
  _ClienteDetalleDialogState createState() => _ClienteDetalleDialogState();
}

class _ClienteDetalleDialogState extends State<ClienteDetalleDialog>
    with SingleTickerProviderStateMixin {
  final ClienteService _clienteService = ClienteService();
  late TabController _tabController;

  // Estados de carga y datos
  bool _isClienteLoading = true;
  String? _clienteErrorMessage;
  Cliente? _cliente;

  bool _isHistorialLoading = true;
  String? _historialErrorMessage;
  List<HistorialGrupo> _historial = [];

  bool _isUpdatingMultigrupo = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchData();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isClienteLoading = true;
      _isHistorialLoading = true;
      _clienteErrorMessage = null;
      _historialErrorMessage = null;
    });

    final clienteFuture = _clienteService.getCliente(widget.idCliente);
    final historialFuture = _clienteService.getHistorialCliente(
      widget.idCliente,
    );
    final results = await Future.wait([clienteFuture, historialFuture]);

    if (!mounted) return;

    final clienteResponse = results[0] as ApiResponse<Map<String, dynamic>>;
    if (clienteResponse.success && clienteResponse.data != null) {
      _cliente = Cliente.fromJson(clienteResponse.data!);
    } else {
      _clienteErrorMessage =
          clienteResponse.error ??
          "No se pudieron cargar los detalles del cliente.";
    }

    final historialResponse = results[1] as ApiResponse<List<HistorialGrupo>>;
    if (historialResponse.success) {
      _historial = historialResponse.data ?? [];
    } else {
      _historialErrorMessage =
          historialResponse.error ?? "No se pudo cargar el historial.";
    }

    setState(() {
      _isClienteLoading = false;
      _isHistorialLoading = false;
    });
  }

  Future<void> _handleHabilitarMultigrupo() async {
    setState(() => _isUpdatingMultigrupo = true);

    final response = await _clienteService.habilitarMultigrupo(
      widget.idCliente,
    );

    if (!mounted) return;

    if (response.success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cliente habilitado para un nuevo grupo correctamente.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${response.error ?? "Ocurrió un problema."}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() => _isUpdatingMultigrupo = false);
  }

  void _mostrarDialogoConfirmacion() {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: colors.backgroundCard,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.group_add_outlined,
                    size: 60,
                    color: colors.brandPrimary,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Confirmar Acción',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '¿Realmente quiere habilitar a este cliente?\n\nEste cliente cambiará de estado para permitir entrar a otro grupo, pero una vez esté en otro grupo volverá a su estado normal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                            side: BorderSide(color: colors.divider),
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.brandPrimary,
                            foregroundColor: colors.whiteWhite,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _handleHabilitarMultigrupo();
                          },
                          child: const Text(
                            'Confirmar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
                onPressed:
                    _isUpdatingMultigrupo ? null : _mostrarDialogoConfirmacion,
                backgroundColor: colors.brandPrimary,
                icon:
                    _isUpdatingMultigrupo
                        ? null
                        : Icon(
                          Icons.group_add_outlined,
                          color: colors.whiteWhite,
                        ),
                // <<< CAMBIO PRINCIPAL AQUÍ >>>
                // Envolvemos el contenido del label en un Container para poder
                // añadir padding horizontal extra solo en desktop.
                label: Container(
                  padding: EdgeInsets.symmetric(
                    // Usamos la extensión para verificar si es desktop
                    // y aplicamos un padding horizontal de 60. En otros tamaños, es 0.
                    vertical: 0,
                    horizontal: context.isDesktop ? 100.0 : 0.0,
                  ),
                  child:
                      _isUpdatingMultigrupo
                          ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: colors.whiteWhite,
                              strokeWidth: 2.5,
                            ),
                          )
                          : Text(
                            'Habilitar Multigrupo',
                            style: TextStyle(
                              color: colors.whiteWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container(
        decoration: BoxDecoration(
          color: colors.backgroundPrimary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child:
                  _isClienteLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: colors.brandPrimary,
                        ),
                      )
                      : _clienteErrorMessage != null || _cliente == null
                      ? _buildErrorState(
                        _clienteErrorMessage,
                        onRetry: _fetchData,
                      )
                      : _buildDetailContent(themeProvider),
            ),
          ],
        ),
      ),
    );
  }

  // (El resto del código permanece sin cambios)
  // ...

  Widget _buildDetailContent(ThemeProvider themeProvider) {
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;
    final clienteInfo = _cliente!.clienteInfo;
    final fullName =
        '${clienteInfo.nombres} ${clienteInfo.apellidoP} ${clienteInfo.apellidoM}'
            .trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: _buildQuickStats(colors, isDarkMode, clienteInfo),
              ),
            ],
          ),
        ),
        _buildModernTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInformacionTab(colors, isDarkMode),
              _buildFinanzasTab(colors, isDarkMode),
              _buildReferenciasTab(colors, isDarkMode),
              _buildHistorialTab(colors, isDarkMode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTabBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      height: 48,
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colors.brandPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: colors.whiteWhite,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: 'Información'),
          Tab(text: 'Finanzas'),
          Tab(text: 'Adicional'),
          Tab(text: 'Historial'),
        ],
      ),
    );
  }

  Widget _buildInformacionTab(colors, bool isDarkMode) {
    final clienteInfo = _cliente!.clienteInfo;
    final domicilio = _cliente!.domicilio;

    final List<Widget> sections = [
      _buildInfoSection(
        "Información Personal",
        [
          _buildInfoItem(
            'Teléfono',
            _displayValue(clienteInfo.telefono),
            Icons.phone_rounded,
          ),
          _buildInfoItem(
            'Email',
            _displayValue(clienteInfo.email),
            Icons.alternate_email_rounded,
          ),
          _buildInfoItem(
            'Fecha de Nacimiento',
            _formatDate(clienteInfo.fechaNac),
            Icons.cake_rounded,
          ),
          _buildInfoItem(
            'Sexo',
            _displayValue(clienteInfo.sexo),
            Icons.wc_rounded,
          ),
          _buildInfoItem(
            'Dependientes',
            clienteInfo.dependientesEconomicos.toString(),
            Icons.escalator_warning_rounded,
          ),
           _buildInfoItem(
          'Fecha de Creación',
          (clienteInfo.fCreacion),
          Icons.event_rounded,
        ),
        ],
        colors,
        isDarkMode,
      ),
      _buildInfoSection(
        "Información del Cónyuge",
        [
          _buildInfoItem(
            'Nombre',
            _displayValue(clienteInfo.nombreConyuge),
            Icons.person_rounded,
          ),
          _buildInfoItem(
            'Teléfono',
            _displayValue(clienteInfo.telefonoConyuge),
            Icons.phone_forwarded_rounded,
          ),
          _buildInfoItem(
            'Ocupación',
            _displayValue(clienteInfo.ocupacionConyuge),
            Icons.work_history_rounded,
          ),
        ],
        colors,
        isDarkMode,
        emptyMessage: "No se registró información del cónyuge.",
        emptyIcon: Icons.person_off_outlined,
      ),
      _buildInfoSection(
        "Domicilio",
        [
          if (domicilio != null) ...[
            _buildInfoItem(
              'Dirección',
              '${_displayValue(domicilio.calle)} #${_displayValue(domicilio.nExt)}, Int. ${_displayValue(domicilio.nInt, defaultValue: "S/N")}',
              Icons.location_on_rounded,
            ),
            _buildInfoItem(
              'Colonia y CP',
              '${_displayValue(domicilio.colonia)}, C.P. ${_displayValue(domicilio.cp)}',
              Icons.location_city_rounded,
            ),
            _buildInfoItem(
              'Municipio/Estado',
              '${_displayValue(domicilio.municipio)}, ${_displayValue(domicilio.estado)}',
              Icons.map_rounded,
            ),
            _buildInfoItem(
              'Tiempo Viviendo',
              _displayValue(domicilio.tiempoViviendo),
              Icons.timer_rounded,
            ),
          ],
        ],
        colors,
        isDarkMode,
        emptyMessage: "No se registró un domicilio.",
        emptyIcon: Icons.location_off_outlined,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
      child:
          context.isMobile
              ? Column(
                children:
                    sections.map((section) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: section,
                      );
                    }).toList(),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  const double spacing = 20.0;
                  final int crossAxisCount =
                      constraints.maxWidth > kDesktopBreakpoint ? 3 : 2;

                  final List<List<Widget>> rows = [];
                  for (int i = 0; i < sections.length; i += crossAxisCount) {
                    int end =
                        (i + crossAxisCount < sections.length)
                            ? i + crossAxisCount
                            : sections.length;
                    rows.add(sections.sublist(i, end));
                  }

                  return Column(
                    children: List.generate(rows.length, (rowIndex) {
                      final List<Widget> rowItems = rows[rowIndex];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: rowIndex < rows.length - 1 ? spacing : 0,
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: List.generate(crossAxisCount, (
                              itemIndex,
                            ) {
                              if (itemIndex < rowItems.length) {
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right:
                                          itemIndex < crossAxisCount - 1
                                              ? spacing
                                              : 0,
                                    ),
                                    child: rowItems[itemIndex],
                                  ),
                                );
                              } else {
                                return Expanded(child: Container());
                              }
                            }),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
    );
  }

  Widget _buildFinanzasTab(colors, bool isDarkMode) {
    final cuentaBanco = _cliente!.cuentaBanco;
    final ingresos = _cliente!.ingresosEgresos;

    bool _hasBankData(CuentaBanco? cuenta) {
      if (cuenta == null) return false;
      return (cuenta.nombreBanco.isNotEmpty ||
          cuenta.numCuenta.isNotEmpty ||
          cuenta.numTarjeta.isNotEmpty ||
          cuenta.clbIntBanc.isNotEmpty);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          _buildInfoSection(
            "Información Bancaria",
            _hasBankData(cuentaBanco)
                ? [
                  _buildInfoItem(
                    'Banco',
                    _displayValue(cuentaBanco!.nombreBanco),
                    Icons.account_balance_rounded,
                  ),
                  _buildInfoItem(
                    'No. de Cuenta',
                    _displayValue(cuentaBanco.numCuenta),
                    Icons.pin_rounded,
                  ),
                  _buildInfoItem(
                    'No. de Tarjeta',
                    _displayValue(cuentaBanco.numTarjeta),
                    Icons.credit_card_rounded,
                  ),
                  _buildInfoItem(
                    'CLABE',
                    _displayValue(cuentaBanco.clbIntBanc),
                    Icons.vpn_key_rounded,
                  ),
                ]
                : [],
            colors,
            isDarkMode,
            emptyMessage: "No hay información bancaria registrada.",
            emptyIcon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            "Ingresos y Egresos",
            ingresos
                .map((ingreso) => _buildIngresoCard(ingreso, colors))
                .toList(),
            colors,
            isDarkMode,
            emptyMessage: "No se registraron ingresos o egresos.",
            emptyIcon: Icons.receipt_long_outlined,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date, {String format = 'dd/MM/yyyy'}) {
    if (date == null) return "N/A";
    return DateFormat(format, 'es_MX').format(date);
  }

  String _displayValue(String? value, {String defaultValue = "No asignado"}) {
    return (value == null || value.trim().isEmpty) ? defaultValue : value;
  }

  Widget _buildHistorialTab(colors, bool isDarkMode) {
    if (_isHistorialLoading) {
      return Center(
        child: CircularProgressIndicator(color: colors.brandPrimary),
      );
    }

    if (_historialErrorMessage != null) {
      return _buildErrorState(_historialErrorMessage, onRetry: _fetchData);
    }

    if (_historial.isEmpty) {
      return _buildEmptySectionContent(
        "Este cliente no tiene historial en otros grupos.",
        Icons.history_toggle_off_outlined,
        colors,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      itemCount: _historial.length,
      itemBuilder: (context, index) {
        final item = _historial[index];
        return _buildHistorialCard(item, colors);
      },
    );
  }

  Widget _buildHistorialCard(HistorialGrupo item, colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10.0,
            spreadRadius: 1.0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colors.divider, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayValue(item.nombreGrupo),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayValue(item.detalles),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _getHistorialStatusChip(item.estado, colors),
            ],
          ),
          const Divider(height: 24, thickness: 0.8),
          _buildCardRow(
            'Folio del Crédito',
            _displayValue(item.folio),
            Icons.confirmation_number_outlined,
            colors,
          ),
          _buildCardRow(
            'Tipo de Grupo',
            _displayValue(item.tipoGrupo),
            Icons.category_outlined,
            colors,
          ),
          _buildCardRow(
            'Adicional',
            _displayValue(item.isAdicional),
            Icons.add_circle_outline,
            colors,
          ),
          _buildCardRow(
            'Fecha Creación',
            _formatDate(item.fCreacion),
            Icons.calendar_today_rounded,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _getHistorialStatusChip(String estado, colors) {
    final Color chipColor = _getColorForEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getColorForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'liquidado':
        return const Color(0xFFFAA300);
      case 'disponible':
        return Colors.green;
      case 'finalizado':
        return Colors.red;
      case 'activo':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildQuickStats(colors, bool isDarkMode, ClienteInfo clienteInfo) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Ocupación',
            _displayValue(clienteInfo.ocupacion, defaultValue: "N/A"),
            Icons.work_outline_rounded,
            colors,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tipo Cliente',
            _displayValue(clienteInfo.tipoCliente, defaultValue: "N/A"),
            Icons.person_pin_circle_outlined,
            colors,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Estado Civil',
            _displayValue(clienteInfo.eCivil, defaultValue: "N/A"),
            Icons.family_restroom_rounded,
            colors,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    colors,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.navigatorBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colors.brandPrimary),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenciasTab(colors, bool isDarkMode) {
    final datosAdicionales = _cliente!.datosAdicionales;
    final referencias = _cliente!.referencias;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          _buildInfoSection(
            "Datos Adicionales",
            [
              if (datosAdicionales != null) ...[
                _buildInfoItem(
                  'CURP',
                  _displayValue(datosAdicionales.curp),
                  Icons.fingerprint,
                ),
                _buildInfoItem(
                  'RFC',
                  _displayValue(datosAdicionales.rfc),
                  Icons.receipt_long_rounded,
                ),
                _buildInfoItem(
                  'Clave de Elector',
                  _displayValue(datosAdicionales.clvElector),
                  Icons.how_to_vote_rounded,
                ),
              ],
            ],
            colors,
            isDarkMode,
            emptyMessage: "No hay datos adicionales registrados.",
            emptyIcon: Icons.description_outlined,
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            "Referencias",
            referencias
                .map((ref) => _buildReferenciaCard(ref, colors))
                .toList(),
            colors,
            isDarkMode,
            emptyMessage: "No se registraron referencias.",
            emptyIcon: Icons.people_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    List<Widget> items,
    colors,
    bool isDarkMode, {
    String? emptyMessage,
    IconData? emptyIcon,
  }) {
    final hasContent = items.any((widget) => widget is! SizedBox);

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (!hasContent && emptyMessage != null)
              _buildEmptySectionContent(
                emptyMessage,
                emptyIcon ?? Icons.info_outline_rounded,
                colors,
              )
            else
              ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, {
    bool isExpanded = false,
  }) {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.backgroundCardDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment:
            isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: colors.brandPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 0),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    height: isExpanded ? 1.4 : 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionContent(String message, IconData icon, colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: colors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngresoCard(IngresoEgreso ingreso, colors) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final monto = double.tryParse(ingreso.montoSemanal) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.backgroundCardDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _displayValue(ingreso.descripcion),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colors.textPrimary,
            ),
          ),
          Text(
            _displayValue(ingreso.tipo_info),
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const Divider(height: 20),
          _buildCardRow(
            'Monto Semanal',
            currencyFormat.format(monto),
            Icons.calendar_today_rounded,
            colors,
          ),
          _buildCardRow(
            'Años de Actividad',
            '${_displayValue(ingreso.aniosActividad, defaultValue: "0")} años',
            Icons.history_toggle_off_rounded,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildReferenciaCard(Referencia referencia, colors) {
    final fullName =
        '${referencia.nombres} ${referencia.apellidoP} ${referencia.apellidoM ?? ''}'
            .trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.backgroundCardDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _displayValue(fullName),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colors.textPrimary,
            ),
          ),
          const Divider(height: 20),
          _buildCardRow(
            'Parentesco',
            _displayValue(referencia.parentesco),
            Icons.group_rounded,
            colors,
          ),
          _buildCardRow(
            'Teléfono',
            _displayValue(referencia.telefono),
            Icons.phone_rounded,
            colors,
          ),
          _buildCardRow(
            'Tiempo de Conocerlo',
            '${_displayValue(referencia.tiempoConocer, defaultValue: "0")} años',
            Icons.timer_rounded,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow(String label, String value, IconData icon, colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.brandPrimary),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          SelectableText(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? errorMessage, {VoidCallback? onRetry}) {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 50),
              const SizedBox(height: 16),
              Text(
                'No se pudo cargar la información',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'Ocurrió un error inesperado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry ?? _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
