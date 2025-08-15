import 'package:finora_app/models/advancedOptionsViewModel.dart';
import 'package:finora_app/models/cliente_monto.dart';
import 'package:finora_app/models/pago.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/pago_service.dart';
import 'package:finora_app/utils/redondeo.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_logger.dart';

// --- IMPORTACIONES NECESARIAS ---

/// Widget que muestra el modal de opciones avanzadas para un pago.
/// Es un StatefulWidget para gestionar el ciclo de vida de los TextEditingControllers.
/// Utiliza ChangeNotifierProvider para crear y proveer el AdvancedOptionsViewModel.
class AdvancedOptionsSheet extends StatefulWidget {
  final Pago pago;
  final String idCredito;
  final List<ClienteMonto> clientesParaRenovar;
  final double saldoFavorTotalAcumulado;
  final VoidCallback onDataChanged;
  final PagoService pagoService; // <--- AÑADE ESTA LÍNEA
  final bool esAdmin; // <-- AÑADE ESTA LÍNEA

  const AdvancedOptionsSheet({
    Key? key,
    required this.pago,
    required this.idCredito,
    required this.clientesParaRenovar,
    required this.saldoFavorTotalAcumulado,
    required this.onDataChanged,
    required this.pagoService, // <--- AÑADE ESTO AL CONSTRUCTOR
    required this.esAdmin, // <-- AÑADE ESTA LÍNEA AL CONSTRUCTOR
  }) : super(key: key);

  @override
  State<AdvancedOptionsSheet> createState() => _AdvancedOptionsSheetState();
}

class _AdvancedOptionsSheetState extends State<AdvancedOptionsSheet> {
  // <<< INICIO DE CAMBIOS (1/3): AÑADIR VARIABLES DE ESTADO >>>
  // Variable para controlar si el modo de edición manual está activo
  bool _moratorioEditable = false;
  // Controller para el campo de texto del monto manual
  late final TextEditingController _moratorioEditableController;
  // <<< FIN DE CAMBIOS (1/3) >>>
  // Los controllers están ligados al ciclo de vida del widget de UI.
  late final Map<String, TextEditingController> _montoRenovacionControllers;
  late final TextEditingController _saldoFavorController;
  final PagoService _pagoService = PagoService();
  late Future<ApiResponse<List<Pago>>> _pagosFuture;

  @override
  void initState() {
    super.initState();
    _montoRenovacionControllers = {};
    _saldoFavorController = TextEditingController();
    // <<< INICIO DE CAMBIOS (2/3): INICIALIZAR EL CONTROLLER >>>
    _moratorioEditableController = TextEditingController();
    // <<< FIN DE CAMBIOS (2/3) >>>
  }

  @override
  void dispose() {
    _montoRenovacionControllers.values.forEach((c) => c.dispose());
    _saldoFavorController.dispose();
    // <<< INICIO DE CAMBIOS (3/3): LIMPIAR EL CONTROLLER >>>
    _moratorioEditableController.dispose();
    // <<< FIN DE CAMBIOS (3/3) >>>
    super.dispose();
  }

  void _recargarPagos() {
    setState(() {
      _pagosFuture = _pagoService.getCalendarioPagos(widget.idCredito);
    });
  }

  // Función para mostrar diálogos de confirmación, se mantiene aquí por ser de UI.
  void _mostrarDialogoConfirmacionEliminar(BuildContext context, Pago pago) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[400]),
                SizedBox(width: 10),
                Text('Confirmar Eliminación'),
              ],
            ),
            content: Text(
              '¿Estás seguro de que deseas eliminar TODOS los pagos registrados para la semana ${pago.semana}?\n\nEsta acción no se puede deshacer.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Cierra el diálogo y procede con la eliminación.
                  Navigator.pop(dialogContext);
                  _ejecutarEliminacion(pago);
                },
                child: Text('Sí, Eliminar'),
              ),
            ],
          ),
    );
  }

  Future<void> _ejecutarEliminacion(Pago pago) async {
    // --- INICIO: Agrega una comprobación 'mounted' por seguridad ---
    // Es una buena práctica, especialmente antes de operaciones asíncronas.
    if (!mounted) return;
    // --- FIN: Agrega una comprobación 'mounted' ---

    final scaffoldMessenger = ScaffoldMessenger.of(
      context,
    ); // Captura el messenger antes de 'await'

    // 1. Obtenemos la lista de abonos que ya están guardados en el servidor.
    //    Estos son los que tienen un ID en el campo 'idpagos'.
    final List<Map<String, dynamic>> abonosAEliminar =
        pago.abonos
            .where(
              (abono) =>
                  abono['idpagos'] != null &&
                  abono['idpagos'].toString().isNotEmpty,
            )
            .toList();

    if (abonosAEliminar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontraron depósitos registrados para eliminar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eliminando ${abonosAEliminar.length} depósito(s)...'),
        backgroundColor: Colors.blue,
      ),
    );

    bool huboError = false;

    // 2. Iteramos sobre cada abono y llamamos al servicio de eliminación.
    for (final abono in abonosAEliminar) {
      try {
        final String idAbono = abono['idpagos'];
        final String idFechasPago = pago.idfechaspagos!;

        AppLogger.log(
          'Eliminando abono: idAbono=$idAbono, idFechasPago=$idFechasPago',
        );

        // Usamos el método que ya existía en el servicio.
        final response = await _pagoService.eliminarAbono(
          idAbono: idAbono,
          idFechasPago: idFechasPago,
        );

        // Comprueba si el widget sigue montado después del await
        if (!mounted) return;

        if (!response.success) {
          // Si un abono falla, marcamos el error y continuamos con los demás.
          huboError = true;
          AppLogger.log(
            'Error al eliminar el abono $idAbono: ${response.error}',
          );
          // Opcional: podrías detener el proceso aquí si lo prefieres.
          // break;
        }
      } catch (e) {
        if (!mounted) return;
        huboError = true;
        AppLogger.log('Excepción al eliminar el abono ${abono['idpagos']}: $e');
        // break; // Detener en caso de excepción de red, etc.
      }
    }

    // 3. Al finalizar el bucle, mostramos un resultado final y recargamos.
    if (huboError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ocurrió un error al eliminar algunos depósitos. Por favor, revisa.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pagos eliminados exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );

      // ----------- LA LÍNEA CLAVE -----------
      // Si todo salió bien, ahora sí cerramos el modal.
      Navigator.pop(context);
      // ----------------------------------------
    }

    // 4. Recargamos la lista de pagos desde el servidor para reflejar los cambios.
    _recargarPagos();
    widget.onDataChanged();
  }

  String formatearNumero(double numero) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(numero);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // Creamos y proveemos el ViewModel aquí. Solo existirá mientras el modal esté visible.
    return ChangeNotifierProvider(
      create:
          (context) => AdvancedOptionsViewModel(
            // Obtenemos el PagoService del Provider que debe estar más arriba en el árbol de widgets.
            pagoService: widget.pagoService, // <--- CAMBIA ESTA LÍNEA
            pago: widget.pago,
            idCredito: widget.idCredito,
            clientesParaRenovar: widget.clientesParaRenovar,
            saldoFavorTotalAcumulado: widget.saldoFavorTotalAcumulado,
            onDataChanged: widget.onDataChanged,
          ),
      // Consumer se reconstruirá cada vez que notifyListeners() es llamado en el ViewModel.
      child: Consumer<AdvancedOptionsViewModel>(
        builder: (context, viewModel, child) {
          final colors = themeProvider.colors;
          final isDarkMode = themeProvider.isDarkMode;

          return Container(
            decoration: BoxDecoration(
              color: colors.backgroundPrimary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle para arrastrar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white30 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                ),

                // Fila de Título con Botón de Regreso
                _buildHeader(context, viewModel),

                const SizedBox(height: 16),

                // AnimatedSwitcher para transiciones suaves entre vistas
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _buildCurrentView(context, viewModel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Construye la cabecera del modal (título y botón de regreso).
  Widget _buildHeader(
    BuildContext context,
    AdvancedOptionsViewModel viewModel,
  ) {
    String titulo = '';
    switch (viewModel.vistaActual) {
      case OpcionVista.menuPrincipal:
        titulo = 'Opciones para Semana ${widget.pago.semana}';
        break;
      case OpcionVista.moratorios:
        titulo = 'Detalles de Moratorios';
        break;
      case OpcionVista.renovacion:
        titulo = 'Clientes a Renovar';
        break;
      case OpcionVista.saldoFavor:
        titulo = 'Utilizar Saldo a Favor';
        break;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (viewModel.vistaActual != OpcionVista.menuPrincipal)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed:
                  () => viewModel.cambiarVista(OpcionVista.menuPrincipal),
              tooltip: 'Volver al menú',
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Determina qué vista construir basándose en el estado del ViewModel.
  Widget _buildCurrentView(
    BuildContext context,
    AdvancedOptionsViewModel viewModel,
  ) {
    // Usar la Key asegura que el AnimatedSwitcher identifique correctamente el cambio de widget.
    switch (viewModel.vistaActual) {
      case OpcionVista.moratorios:
        return Container(
          key: const ValueKey('vista_moratorios'),
          child: _buildVistaMoratorios(context, viewModel),
        );
      case OpcionVista.renovacion:
        return Container(
          key: const ValueKey('vista_renovacion'),
          child: _buildVistaRenovacion(context, viewModel),
        );
      case OpcionVista.saldoFavor:
        return Container(
          key: const ValueKey('vista_saldofavor'),
          child: _buildVistaSaldoFavor(context, viewModel),
        );
      case OpcionVista.menuPrincipal:
      default:
        return Container(
          key: const ValueKey('menu_principal'),
          child: _buildMenuPrincipal(context, viewModel),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // --- SUB-WIDGETS PARA CADA VISTA ---
  // ---------------------------------------------------------------------------

  Widget _buildMenuPrincipal(
    BuildContext context,
    AdvancedOptionsViewModel viewModel,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final bool sePuedeEliminar =
        (widget.pago.sumaDepositoMoratorisos ?? 0.0) > 0;
    final bool tieneInfoMoratorios = widget.pago.moratorios != null;

    // --- LÓGICA PARA RENOVAR (Ya la tenías) ---
    final bool hayRenovacionesGuardadas =
        widget.pago.renovacionesPendientes.isNotEmpty;
    String subtituloRenovacion;
    if (hayRenovacionesGuardadas) {
      final int numGuardados = widget.pago.renovacionesPendientes.length;
      subtituloRenovacion =
          (numGuardados == 1)
              ? '1 cliente a renovar'
              : '$numGuardados clientes a renovar';
    } else {
      final int numDisponibles = widget.clientesParaRenovar.length;
      subtituloRenovacion =
          (numDisponibles == 1)
              ? '1 cliente disponible'
              : '$numDisponibles clientes disponibles';
    }

    // <<< INICIO DEL CAMBIO SOLICITADO >>>
    // 1. Verificamos si ya hay un saldo a favor aplicado en este pago.
    //    Usamos el mismo campo que la vista de detalles: `favorUtilizado`.
    final double saldoAplicado = widget.pago.favorUtilizado ?? 0.0;

    // 2. Creamos el texto del subtítulo dinámicamente.
    String subtituloSaldoFavor;
    if (saldoAplicado > 0) {
      // Si ya hay un monto aplicado, lo mostramos formateado.
      subtituloSaldoFavor =
          'Saldo a favor aplicado: \$${formatearNumero(saldoAplicado)}';
    } else {
      // Si no, mostramos el mensaje por defecto.
      subtituloSaldoFavor = 'Aplicar saldo disponible';
    }
    // <<< FIN DEL CAMBIO SOLICITADO >>>

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tieneInfoMoratorios)
          _buildOptionTile(
            icon: Icons.info_outline,
            title: 'Ver Moratorios',
            subtitle:
                widget.pago.moratorios!.moratorios > 0
                    ? 'Calculado: \$${formatearNumero(widget.pago.moratorios!.moratorios)}'
                    : 'Revisar detalles de retraso',
            color: Colors.blue,
            onTap: () => viewModel.cambiarVista(OpcionVista.moratorios),
            isDarkMode: isDarkMode,
          ),
        _buildOptionTile(
          icon: Icons.person_add_outlined,
          title: 'Clientes a Renovar',
          subtitle: subtituloRenovacion,
          color: Colors.purple,
          onTap: () => viewModel.cambiarVista(OpcionVista.renovacion),
          isDarkMode: isDarkMode,
        ),
        _buildOptionTile(
          icon: Icons.savings_outlined,
          title: 'Utilizar Saldo a Favor',
          // <<< 3. Usamos la variable con el texto dinámico. >>>
          subtitle: subtituloSaldoFavor,
          color: Colors.green,
          onTap: () => viewModel.cambiarVista(OpcionVista.saldoFavor),
          isDarkMode: isDarkMode,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Divider(color: themeProvider.colors.divider, thickness: 1),
        ),
        if (sePuedeEliminar && widget.esAdmin)
          _buildOptionTile(
            icon: Icons.delete_forever_outlined,
            title: 'Eliminar Pago',
            subtitle: 'Borra todos los depósitos de esta semana',
            color: Colors.red[400]!,
            onTap: () {
              _mostrarDialogoConfirmacionEliminar(context, widget.pago);
            },
            isDarkMode: isDarkMode,
          ),
      ],
    );
  }

  // En tu archivo lib/widgets/pago/advanced_options_sheet.dart

  // ... (dentro de la clase _AdvancedOptionsSheetState)

  // Código completo de la función para copiar y pegar:
  Widget _buildVistaMoratorios(
    BuildContext context,
    AdvancedOptionsViewModel viewModel,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final moratorios = widget.pago.moratorios;

    // Se obtienen los datos del usuario para la lógica de roles
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final esAdmin = userData.tipoUsuario == 'Admin';
    final puedeEditar = userData.tipoUsuario != 'Invitado';

    if (moratorios == null) {
      return const Center(
        child: Text("No hay información de moratorios disponible."),
      );
    }

    // Se verifica si se puede editar el monto (si ya hay un abono registrado)
    final bool puedeEditarMonto = viewModel.tieneAbonosGuardados;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SECCIÓN DE INFORMACIÓN GENERAL ---
        _buildInfoRow(
          icon: Icons.date_range_outlined,
          label: 'Semanas de retraso',
          value: '${moratorios.semanasDeRetraso}',
          isDarkMode: isDarkMode,
        ),
        _buildInfoRow(
          icon: Icons.today_outlined,
          label: 'Días de retraso',
          value: '${moratorios.diferenciaEnDias}',
          isDarkMode: isDarkMode,
        ),
        _buildInfoRow(
          icon: Icons.attach_money_outlined,
          label: 'Monto calculado',
          value: '\$${formatearNumero(moratorios.moratorios)}',
          isDarkMode: isDarkMode,
          valueColor: Colors.orange,
        ),
        _buildInfoRow(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Monto Total (Pago + Moratorio)',
          value: '\$${formatearNumero(moratorios.montoTotal)}',
          isDarkMode: isDarkMode,
          valueColor: Colors.red,
        ),
        if (moratorios.mensaje.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    moratorios.mensaje,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

        const Divider(height: 30, thickness: 1),

        // --- SECCIÓN DE CONTROLES ---

        // BLOQUE 1: Moratorio Editable (Switch + Campo de Texto/Mensaje)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // El Switch solo lo ve el Admin
            if (esAdmin)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Habilitar moratorio editable',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Permite ingresar un monto manual.',
                  style: TextStyle(fontSize: 12),
                ),
                value: viewModel.moratorioEditableHabilitado,
                activeColor: Colors.purple,
                secondary: const Icon(Icons.edit_note, color: Colors.purple),
                onChanged:
                    viewModel.isSaving
                        ? null
                        : (bool newValue) async {
                          final success = await viewModel
                              .actualizarPermisoMoratorioEditable(newValue);
                          if (mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Permiso actualizado.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al actualizar.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
              ),

            // El campo de texto o el mensaje de "pagado" lo ven todos los usuarios no-invitados
            if (puedeEditar)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child:
                    viewModel.moratorioEditableHabilitado
                        ? (viewModel.moratorioManualEstaPagado
                            // Caso 1: Habilitado Y ya está pagado -> Mostrar mensaje de éxito
                            ? Container(
                              key: const ValueKey('moratorio_pagado'),
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green[700],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'El moratorio manual ya fue cubierto.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isDarkMode
                                                ? Colors.green[200]
                                                : Colors.green[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            // Caso 2: Habilitado pero NO pagado -> Mostrar campo para editar
                            : Padding(
                              key: const ValueKey('moratorio_textfield'),
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller:
                                              viewModel
                                                  .moratorioEditableController,
                                          enabled:
                                              !viewModel.isSaving &&
                                              puedeEditarMonto,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: InputDecoration(
                                            labelText: 'Monto Moratorio Manual',
                                            hintText: '0.00',
                                            prefixText: '\$ ',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor:
                                                puedeEditarMonto
                                                    ? themeProvider
                                                        .colors
                                                        .backgroundCard
                                                    : themeProvider
                                                        .colors
                                                        .disabledCard,
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed:
                                            viewModel.isSaving ||
                                                    !puedeEditarMonto
                                                ? null
                                                : () async {
                                                  final success =
                                                      await viewModel
                                                          .guardarMoratorioManual();
                                                  if (mounted && success) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Moratorio guardado con éxito.',
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                    Navigator.pop(context);
                                                  } else if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Error al guardar. Verifica el monto.',
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                },
                                        child:
                                            viewModel.isSaving
                                                ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                                : const Icon(Icons.save_alt),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                          foregroundColor: Colors.white,
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!puedeEditarMonto)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8.0,
                                        left: 4.0,
                                      ),
                                      child: Text(
                                        'Primero debes registrar un pago para esta semana.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ))
                        // Caso 3: La función no está habilitada en absoluto -> No mostrar nada
                        : const SizedBox.shrink(
                          key: ValueKey('moratorio_empty'),
                        ),
              ),
          ],
        ),

        // BLOQUE 2: Deshabilitar Moratorios (solo Admin)
        if (esAdmin)
          Column(
            children: [
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Deshabilitar moratorios',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'El cliente no pagará moratorios para esta semana.',
                  style: TextStyle(fontSize: 12),
                ),
                value: viewModel.estadoMoratorioSwitch == "Si",
                activeColor: Colors.red,
                secondary: const Icon(Icons.block, color: Colors.red),
                onChanged:
                    viewModel.isSaving
                        ? null
                        : (bool newValue) async {
                          final success = await viewModel
                              .actualizarPermisoMoratorio(newValue);
                          if (mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Permiso actualizado con éxito'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al actualizar el permiso'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
              ),
            ],
          ),
      ],
    );
  }

  // En tu archivo lib/widgets/pago/advanced_options_sheet.dart

  // ... (dentro de la clase _AdvancedOptionsSheetState)

  Widget _buildVistaRenovacion(
    BuildContext context,
    AdvancedOptionsViewModel viewModel,
  ) {
    // Obtenemos los proveedores una sola vez
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    // Obtenemos datos relevantes para la UI
    final pagoFinalizado =
        widget.pago.estado?.toLowerCase().contains('pagado') ?? false;

    // El `Consumer` ya nos notifica de los cambios, por lo que podemos construir la UI directamente
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Lista de Clientes (con Scroll) ---
        // Para solucionar el problema de la lista muy larga, se envuelve en un
        // `Container` con una altura máxima (`maxHeight`) y se usa un `ListView.builder`
        // para que la lista sea desplazable si su contenido excede esa altura.
        // Esto mantiene el tamaño del diálogo consistente.
        Container(
          // Puedes ajustar esta altura según el diseño que prefieras.
          constraints: const BoxConstraints(maxHeight: 350),
          child: ListView.builder(
            shrinkWrap:
                true, // Esencial para que el ListView funcione dentro del Container.
            itemCount: widget.clientesParaRenovar.length,
            itemBuilder: (context, index) {
              final cliente = widget.clientesParaRenovar[index];
              // La lógica que antes estaba en el `.map()` se mueve aquí.
              final idCliente = cliente.idclientes!;
              final isSelected = viewModel.clientesSeleccionados.contains(
                idCliente,
              );
              final isSaved = widget.pago.renovacionesPendientes.any(
                (r) => r.idclientes == idCliente,
              );
              _montoRenovacionControllers.putIfAbsent(idCliente, () {
                final montoInicial = viewModel.montosEditados[idCliente] ?? 0.0;
                return TextEditingController(
                  text: formatearNumero(montoInicial),
                );
              });
              final montoActualViewModel =
                  viewModel.montosEditados[idCliente] ?? 0.0;
              final controller = _montoRenovacionControllers[idCliente]!;
              if (double.tryParse(controller.text.replaceAll(',', '')) !=
                  montoActualViewModel) {
                controller.text = formatearNumero(montoActualViewModel);
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
              }

              return _buildClienteRenovacionTile(
                cliente: cliente,
                isSelected: isSelected,
                isSaved: isSaved,
                controller: controller,
                isDarkMode: isDarkMode,
                pagoFinalizado: pagoFinalizado,
                onSelect:
                    (value) =>
                        viewModel.toggleClienteRenovacion(idCliente, value),
                onMontoChanged:
                    (newMonto) => viewModel.actualizarMontoRenovacion(
                      idCliente,
                      newMonto,
                    ),
              );
            },
          ),
        ),

        // ===================================================================
        // --- INICIO DE LA SECCIÓN DE TOTALES ---
        // (Esta sección no se modifica)
        // ===================================================================

        // --- Resumen de Totales ---
        Container(
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila para el Total Seleccionado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Seleccionado:",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Text(
                    '\$${formatearNumero(viewModel.totalRenovacionSeleccionado)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Fila para el Total a Pagar (Objetivo)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total a Pagar (Objetivo):",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Text(
                    // Asume que viewModel.totalObjetivo existe
                    '\$${formatearNumero(redondearDecimales(viewModel.totalObjetivo, context))}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          colors.brandPrimary, // Color de marca para destacar
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ===================================================================
        // --- FIN DE LA SECCIÓN DE TOTALES ---
        // ===================================================================

        Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                   "Al guardar los clientes a renovar el pago se tomará como pagado.",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

         const SizedBox(height: 24),

        // --- Botones de Acción ---
        // Esta sección no cambia
        Row(
          children: [
            if (viewModel.hayRenovacionesGuardadas)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      viewModel.isDeleting || viewModel.isSaving
                          ? null
                          : () async {
                            final success =
                                await viewModel.eliminarRenovacion();
                            if (mounted && success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Selección eliminada con éxito.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Error al eliminar la selección.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                  icon:
                      viewModel.isDeleting
                          ? const SizedBox.shrink()
                          : const Icon(Icons.delete_outline),
                  label:
                      viewModel.isDeleting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            if (viewModel.hayRenovacionesGuardadas) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    viewModel.isSaving || viewModel.isDeleting || pagoFinalizado
                        ? null
                        : () async {
                          final success = await viewModel.guardarRenovacion();
                          if (mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Selección guardada con éxito.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo guardar la selección.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                icon:
                    viewModel.isSaving
                        ? const SizedBox.shrink()
                        : Icon(Icons.save_alt, color: colors.iconButton),
                label:
                    viewModel.isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          'Guardar',
                          style: TextStyle(color: colors.textButton),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.brandPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper que construye la fila para un cliente en la lista de renovación.
  /// Se mantiene aquí porque es un componente de UI puro.
  Widget _buildClienteRenovacionTile({
    required ClienteMonto cliente,
    required bool isSelected,
    required bool isSaved,
    required TextEditingController controller,
    required bool isDarkMode,
    required bool pagoFinalizado,
    required ValueChanged<bool> onSelect,
    required ValueChanged<double> onMontoChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged:
                isSaved || pagoFinalizado
                    ? null
                    : (val) => onSelect(val ?? false),
            activeColor: Colors.purple,
          ),
          Expanded(
            child: Text(
              cliente.nombreCompleto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isSaved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'GUARDADO',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 4),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.right,
              enabled: !isSaved && !pagoFinalizado,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13, // <-- aquí defines el tamaño
              ),
              decoration: InputDecoration(
                prefixText: '\$ ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                final double newMonto =
                    double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                onMontoChanged(newMonto);
              },
              onTap: () {
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controller.text.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaSaldoFavor(
    BuildContext context,
    AdvancedOptionsViewModel viewModel,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // --- 1. DEFINICIÓN DE VARIABLES DE ESTADO ---
    final double montoAPagar = widget.pago.saldoEnContra ?? 0.0;
    final double favorYaUtilizado = widget.pago.favorUtilizado ?? 0.0;
    final bool pagoFinalizado = widget.pago.estaFinalizado;
    final double saldoTotalDisponible = viewModel.saldoFavorTotalAcumulado;

    // --- 2. LÓGICA DE VISUALIZACIÓN DE ESCENARIOS ---
    final bool hayDeuda = montoAPagar > 0.01;
    final bool haySaldoDisponible = saldoTotalDisponible > 0.01;

    // La condición clave para mostrar el widget de aplicar saldo
    final bool mostrarWidgetAplicarSaldo =
        !pagoFinalizado && hayDeuda && haySaldoDisponible;

    // La condición para mostrar el mensaje de "Guarde un abono" (si la tuvieras)
    // Nota: Basado en tu lógica anterior, esta ya no sería necesaria si el servidor
    // acepta IDs nulos, pero la dejamos por si acaso.
    // final bool mostrarAvisoGuardarAbono = !pagoFinalizado && !hayDeuda && haySaldoDisponible;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, // Mejor alineación
      children: [
        // --- FILAS DE INFORMACIÓN (Header) ---
        // (Esta parte no cambia)
        _buildInfoRow(
          icon: Icons.account_balance_wallet_outlined,
          label: "Saldo Total Disponible",
          value: "\$${formatearNumero(saldoTotalDisponible)}",
          isDarkMode: isDarkMode,
          valueColor: Colors.green,
        ),
        if (favorYaUtilizado > 0)
          _buildInfoRow(
            icon: Icons.check_circle_outline,
            label: "Saldo a favor ya aplicado",
            value: "\$${formatearNumero(favorYaUtilizado)}",
            isDarkMode: isDarkMode,
            valueColor: Colors.blue.shade300,
          ),
        if (montoAPagar > 0 && !pagoFinalizado)
          _buildInfoRow(
            icon: Icons.warning_amber_rounded,
            label: "Deuda restante en este pago",
            value: "\$${formatearNumero(montoAPagar)}",
            isDarkMode: isDarkMode,
            valueColor: Colors.orange,
          ),
        const Divider(height: 32),

        // --- WIDGETS DE ESCENARIOS ---

        // Escenario 1: El pago ya está liquidado (Máxima prioridad)
        if (pagoFinalizado)
          _buildInfoMessage(
            text: "Este pago ya está liquidado.",
            icon: Icons.verified_outlined,
            color: Colors.green,
            isDarkMode: isDarkMode,
          ),

        // Escenario 2 (UNIFICADO): Widget para aplicar saldo a favor
        if (mostrarWidgetAplicarSaldo)
          _buildAplicarParcialWidget(
            // Siempre usamos este widget
            context: context,
            viewModel: viewModel,
            // El monto máximo aplicable es el menor entre el saldo y la deuda
            montoMaximo:
                (saldoTotalDisponible < montoAPagar)
                    ? saldoTotalDisponible
                    : montoAPagar,
            isDarkMode: isDarkMode,
            controller: _saldoFavorController,
          ),

        // Escenario 3: No hay deuda, no hay nada que hacer con el saldo aquí.
        if (!pagoFinalizado && !hayDeuda && haySaldoDisponible)
          _buildInfoMessage(
            text:
                "Este pago no tiene deuda pendiente. El saldo a favor no se puede aplicar.",
            icon: Icons.info_outline,
            color: Colors.blue,
            isDarkMode: isDarkMode,
          ),

        // Escenario 4: No hay saldo disponible
        if (!pagoFinalizado && hayDeuda && !haySaldoDisponible)
          _buildInfoMessage(
            text:
                "No tienes saldo a favor disponible para aplicar a esta deuda.",
            icon: Icons.info_outline,
            color: Colors.orange,
            isDarkMode: isDarkMode,
          ),
      ],
    );
  }

  /// Helper para mostrar mensajes informativos con ícono y color.
  Widget _buildInfoMessage({
    required String text,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    final textPrimaryColor =
        Provider.of<ThemeProvider>(context, listen: false).colors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textPrimaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para el escenario de "Aplicar monto parcial" del saldo a favor.
  Widget _buildAplicarParcialWidget({
    required BuildContext context,
    required AdvancedOptionsViewModel viewModel,
    required double montoMaximo,
    required bool isDarkMode,
    required TextEditingController controller,
  }) {
    // Inicializa el controller con el monto máximo la primera vez que se construye.
    // Esto inteligentemente sugiere "cubrir completo" si es posible.
    if (controller.text.isEmpty) {
      controller.text = montoMaximo.toStringAsFixed(2);
      // Mueve el cursor al final para facilitar la edición
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Monto a Utilizar:",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !viewModel.isSaving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '\$ ',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: "Máx: \$${formatearNumero(montoMaximo)}",
            helperText: "Puedes editar este monto.", // Pequeña ayuda al usuario
          ),
          // Valida que el monto ingresado no exceda el máximo aplicable.
          onChanged: (value) {
            final double montoIngresado = double.tryParse(value) ?? 0.0;
            if (montoIngresado > montoMaximo) {
              // Corrige automáticamente al valor máximo si se excede
              controller.text = montoMaximo.toStringAsFixed(2);
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                viewModel.isSaving
                    ? null
                    : () async {
                      // Obtiene el monto final del controlador de texto
                      final double montoFinal =
                          double.tryParse(controller.text) ?? 0.0;

                      // Pequeña validación para no enviar ceros o valores negativos
                      if (montoFinal <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("El monto debe ser mayor a cero."),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return; // No continuar
                      }

                      // Llama al ViewModel para ejecutar la lógica de negocio
                      final success = await viewModel.aplicarSaldoFavor(
                        montoFinal,
                      );

                      if (!mounted)
                        return; // Buena práctica después de un await

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Monto aplicado con éxito."),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Error al aplicar el monto."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
            icon:
                viewModel.isSaving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.download_done),
            label:
                viewModel.isSaving
                    ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                    : const Text(
                      "Aplicar Monto de Saldo",
                    ), // Texto más genérico
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // --- WIDGETS AUXILIARES (Helpers de UI) ---
  // ---------------------------------------------------------------------------

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDarkMode ? Colors.white54 : Colors.grey[600],
            size: 20,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDarkMode ? Colors.white : Colors.black87),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode ? Colors.white30 : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
