import 'package:finora_app/models/cliente_monto.dart';
import 'package:finora_app/models/pago.dart';
import 'package:finora_app/services/pago_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_logger.dart';


// --- IMPORTACIONES NECESARIAS ---
// Asegúrate de reemplazar 'tu_proyecto' con el nombre real de tu paquete.


/// Define las diferentes vistas/pantallas dentro del modal de opciones avanzadas.
/// Usar un enum previene errores de tipeo y hace el código más legible.
enum OpcionVista { menuPrincipal, moratorios, renovacion, saldoFavor }

/// ViewModel para el modal de Opciones Avanzadas de un Pago.
///
/// Esta clase encapsula TODO el estado y la lógica de negocio,
/// manteniendo el widget de la UI limpio y declarativo.
/// Hereda de ChangeNotifier para notificar a los widgets cuando los datos cambian.
class AdvancedOptionsViewModel extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // --- DEPENDENCIAS INYECTADAS (el cerebro necesita estas herramientas) ---
  // ---------------------------------------------------------------------------

  final PagoService _pagoService;
  final String _idCredito;
  final Pago _pago;
  final List<ClienteMonto> _clientesParaRenovar;
  final double saldoFavorTotalAcumulado; // Se calcula fuera y se pasa

  /// Callback para notificar al widget padre que los datos han cambiado y
  /// necesita recargar la lista de pagos.
  final VoidCallback onDataChanged;

  // --- NUEVA PROPIEDAD ---
  double _totalObjetivo = 0.0;
  double get totalObjetivo => _totalObjetivo;

  // ---------------------------------------------------------------------------
  // --- ESTADO INTERNO DE LA UI (lo que la vista necesita saber) ---
  // ---------------------------------------------------------------------------

  /// La vista que se está mostrando actualmente en el modal.
  OpcionVista _vistaActual = OpcionVista.menuPrincipal;

  /// Controla el estado de carga para operaciones de guardado/actualización.
  bool _isSaving = false;

  /// Controla el estado de carga para operaciones de eliminación.
  bool _isDeleting = false;

  /// Estado del switch para deshabilitar moratorios ("Si" o "No").
  late String _estadoMoratorioSwitch;

  /// Conjunto de IDs de clientes seleccionados para renovación.
  Set<String> _clientesSeleccionados = {};

  /// Mapa de montos de renovación editados por el usuario.
  /// La clave es el ID del cliente, el valor es el monto.
  Map<String, double> _montosEditados = {};
  
   // <<< AÑADIR >>>
  // --- ESTADO PARA MORATORIO EDITABLE ---
  
  /// Controla si el switch de "moratorio editable" está activado o no.
  late bool moratorioEditableHabilitado;

  /// Controller para el campo de texto donde se ingresa el monto manual.
  late TextEditingController moratorioEditableController;
  // <<< FIN DE AÑADIR >>>

  // ---------------------------------------------------------------------------
  // --- GETTERS PÚBLICOS (forma segura para que la UI lea el estado) ---
  // ---------------------------------------------------------------------------

  OpcionVista get vistaActual => _vistaActual;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String get estadoMoratorioSwitch => _estadoMoratorioSwitch;
  Set<String> get clientesSeleccionados => _clientesSeleccionados;
  Map<String, double> get montosEditados => _montosEditados;

  /// GETTER DERIVADO: Calcula el total de los montos de renovación seleccionados.
  double get totalRenovacionSeleccionado {
    return _clientesSeleccionados.fold(0.0, (sum, idCliente) {
      return sum + (_montosEditados[idCliente] ?? 0.0);
    });
  }

   // Modifica o crea un método de inicialización para calcular el total objetivo
  void inicializarDatos(Pago pago, List<Pago> allPagos, List<ClienteMonto> clientesParaRenovar, double pagoCuotaTotal) {
    // ... tu lógica de inicialización existente ...

    // --- LÓGICA COPIADA Y ADAPTADA DE TU CÓDIGO DESKTOP ---
    final double totalOriginal = clientesParaRenovar.fold(0.0, (sum, cliente) => sum + cliente.capitalMasInteres);
    double totalCalculado = totalOriginal; // Puedes usar tu función redondearDecimales

    // Aquí va la misma lógica que tenías para ver si se aplica un descuento
    // por garantía en la última semana.
    // ... (la lógica de vistaConDescuento)
    // if (vistaConDescuento) {
    //   totalCalculado = nuevoMontoFichaTotal;
    // }

    _totalObjetivo = totalCalculado;

    // Notificar a los listeners que los datos están listos
    notifyListeners();
  }
  
  /// GETTER DERIVADO: Verifica si ya existen renovaciones guardadas para este pago.
  bool get hayRenovacionesGuardadas => _pago.renovacionesPendientes.isNotEmpty;

    // <<< AÑADIR ESTE NUEVO GETTER >>>
  /// Verifica si ya existe al menos un abono guardado en el servidor para este pago.
  /// Esto es crucial para habilitar la adición de moratorios manuales.
  bool get tieneAbonosGuardados {
    // Buscamos en la lista de abonos si alguno tiene un 'idpagos' válido.
    // Esto significa que ya fue registrado en la base de datos.
    return _pago.abonos.any((abono) =>
        abono['idpagos'] != null && abono['idpagos'].toString().isNotEmpty);
  }
  // <<< FIN DEL GETTER >>>

  // ---------------------------------------------------------------------------
  // --- CONSTRUCTOR E INICIALIZACIÓN ---
  // ---------------------------------------------------------------------------

  AdvancedOptionsViewModel({
    required PagoService pagoService,
    required String idCredito,
    required Pago pago,
    required List<ClienteMonto> clientesParaRenovar,
    required this.saldoFavorTotalAcumulado,
    required this.onDataChanged,
  })  : _pagoService = pagoService,
        _idCredito = idCredito,
        _pago = pago,
        _clientesParaRenovar = clientesParaRenovar {
    // Inicializa el estado con los valores del objeto 'pago'
    _estadoMoratorioSwitch = _pago.moratorioDesabilitado ?? "No";
    _inicializarEstadoRenovacion();

    // <<< AÑADIR >>>
    // Inicialización del estado de moratorios
    moratorioEditableHabilitado = _pago.moratorioEditable == "Si";
    moratorioEditableController = TextEditingController();
    // <<< FIN DE AÑADIR >>>


       // ===================================================================
    // --- INICIO DEL CÓDIGO AÑADIDO ---
    // ===================================================================
    // Aquí "agarramos" y calculamos el monto objetivo al crear el ViewModel.
    // Sumamos el valor por defecto de todos los clientes disponibles para renovar.
    _totalObjetivo = _clientesParaRenovar.fold(
      0.0,
      (sum, cliente) => sum + cliente.capitalMasInteres,
    );
    // Si tienes lógica de descuentos (como en tu versión de escritorio), la aplicarías aquí.
    // ===================================================================
    // --- FIN DEL CÓDIGO AÑADIDO ---
    // ===================================================================

  }

  

  /// Configura el estado inicial para la vista de renovación.
  /// Pre-selecciona clientes y carga los montos guardados previamente.
  void _inicializarEstadoRenovacion() {
    final Set<String> seleccionados = {};
    final Map<String, double> montos = {};

    // Pre-cargar datos de renovaciones ya guardadas en el backend
    if (_pago.renovacionesPendientes.isNotEmpty) {
      for (var renovacion in _pago.renovacionesPendientes) {
        seleccionados.add(renovacion.idclientes!);
        montos[renovacion.idclientes!] = renovacion.descuento ?? 0.0;
      }
    }

    // Inicializar montos para todos los clientes (los no guardados toman su valor por defecto)
    for (var cliente in _clientesParaRenovar) {
      if (!montos.containsKey(cliente.idclientes)) {
        montos[cliente.idclientes!] = cliente.capitalMasInteres;
      }
    }

    _clientesSeleccionados = seleccionados;
    _montosEditados = montos;
    // No se notifica a los listeners porque esto ocurre en la construcción.
  }

  // ---------------------------------------------------------------------------
  // --- MÉTODOS PÚBLICOS (acciones que la UI puede disparar) ---
  // ---------------------------------------------------------------------------

  /// Cambia la vista actual del modal y notifica a la UI para que se reconstruya.
  void cambiarVista(OpcionVista nuevaVista) {
    _vistaActual = nuevaVista;
    notifyListeners();
  }
  
  /// Agrega o quita un cliente de la selección de renovación.
  void toggleClienteRenovacion(String clienteId, bool isSelected) {
    final newSet = Set<String>.from(_clientesSeleccionados);
    if (isSelected) {
      newSet.add(clienteId);
    } else {
      newSet.remove(clienteId);
    }
    _clientesSeleccionados = newSet;
    notifyListeners();
  }

  /// Actualiza el monto de descuento para un cliente en la vista de renovación.
  void actualizarMontoRenovacion(String clienteId, double nuevoMonto) {
    final newMontos = Map<String, double>.from(_montosEditados);
    newMontos[clienteId] = nuevoMonto;
    _montosEditados = newMontos;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // --- LÓGICA DE NEGOCIO (comunicación con servicios/API) ---
  // ---------------------------------------------------------------------------

  /// Actualiza el permiso de moratorios para la semana actual.
  /// Devuelve `true` si la operación fue exitosa.
  Future<bool> actualizarPermisoMoratorio(bool deshabilitar) async {
    _setSaving(true);
    final nuevoEstado = deshabilitar ? "Si" : "No";

    final response = await _pagoService.actualizarPermisoMoratorio(
      idFechasPago: _pago.idfechaspagos!,
      moratorioDesabilitado: nuevoEstado,
    );

    if (response.success) {
      _estadoMoratorioSwitch = nuevoEstado;
      _pago.moratorioDesabilitado = nuevoEstado; // Actualiza el modelo local
      onDataChanged(); // Notifica al widget padre para que recargue todo
    }

    _setSaving(false);
    return response.success;
  }

  /// Guarda la selección de clientes y sus montos para renovación.
  /// Devuelve `true` si la operación fue exitosa.
  Future<bool> guardarRenovacion() async {
    _setSaving(true);
    
    final clientesAGuardar = _clientesParaRenovar
        .where((cliente) =>
            _clientesSeleccionados.contains(cliente.idclientes!) &&
            !_pago.renovacionesPendientes.any((r) => r.idclientes == cliente.idclientes))
        .toList();

    if (clientesAGuardar.isEmpty) {
      // Opcional: podrías manejar este caso para mostrar un mensaje.
      _setSaving(false);
      return false; // No hay nada que guardar.
    }

    final List<Map<String, dynamic>> payload = clientesAGuardar.map((cliente) {
      final monto = _montosEditados[cliente.idclientes!] ?? cliente.capitalMasInteres;
      return {
        "iddetallegrupos": cliente.iddetallegrupos,
        "idgrupos": cliente.idgrupos,
        "idclientes": cliente.idclientes,
        "descuento": monto,
      };
    }).toList();

    final response = await _pagoService.guardarSeleccionRenovacion(
      idFechasPago: _pago.idfechaspagos!,
      clientes: payload,
    );

    if (response.success) {
      onDataChanged();
    }
    
    _setSaving(false);
    return response.success;
  }


   // <<< AÑADIR ESTOS DOS NUEVOS MÉTODOS >>>
  
  /// Actualiza el permiso para que el moratorio sea editable.
  /// Llama al servicio `actualizarPermisoMoratorioEditable`.
  Future<bool> actualizarPermisoMoratorioEditable(bool habilitar) async {
    _setSaving(true);
    final response = await _pagoService.actualizarPermisoMoratorioEditable(
      idFechasPagos: _pago.idfechaspagos!,
      habilitar: habilitar,
    );
    if (response.success) {
      // Actualizamos el estado local para que la UI reaccione inmediatamente
      moratorioEditableHabilitado = habilitar;
      _pago.moratorioEditable = habilitar ? "Si" : "No"; // Actualiza el modelo local
      onDataChanged();
    }
    _setSaving(false);
    return response.success;
  }

  /// Guarda el monto del moratorio ingresado manualmente.
  /// Llama al servicio `guardarMoratorioEditable`.
  // Reemplaza esta función completa
/// Guarda el monto del moratorio ingresado manualmente.
/// Llama al servicio `guardarMoratorioEditable`.
Future<bool> guardarMoratorioManual() async {
  // 1. Obtener y validar el monto del controller
  final montoTexto = moratorioEditableController.text.replaceAll(',', '');
  final double monto = double.tryParse(montoTexto) ?? 0.0;

  // No hacemos nada si el monto es inválido
  if (monto <= 0) {
    return false;
  }

  _setSaving(true);

  // 2. Formatear la fecha a YYYY-MM-DD como lo pide la API
  final String fechaFormateada = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // <<< CAMBIO CLAVE AQUÍ >>>
  // Ahora, `montoaPagar` se llena con el valor correcto de la ficha de esa semana.
  final response = await _pagoService.guardarMoratorioEditable(
    idFechasPagos: _pago.idfechaspagos!,
    fechaPago: fechaFormateada,
    montoMoratorio: monto,
    montoAPagar: _pago.capitalMasInteres, // Pasamos el monto de la ficha
  );
  // <<< FIN DEL CAMBIO >>>

  if (response.success) {
    // Si fue exitoso, limpiamos el controller y recargamos datos
    moratorioEditableController.clear();
    onDataChanged();
  }

  _setSaving(false);
  return response.success;
}
  // <<< FIN DE AÑADIR >>>
  
  /// Elimina todas las renovaciones guardadas para esta semana.
  /// Devuelve `true` si la operación fue exitosa.
  Future<bool> eliminarRenovacion() async {
    _setDeleting(true);

    final response = await _pagoService.eliminarSeleccionRenovacion(
      idFechasPago: _pago.idfechaspagos!,
    );
    
    if (response.success) {
      onDataChanged();
    }
    
    _setDeleting(false);
    return response.success;
  }

  /// Aplica un monto del saldo a favor acumulado a la deuda de este pago.
  /// Devuelve `true` si la operación fue exitosa.
  // En AdvancedOptionsViewModel.dart

/// Aplica un monto del saldo a favor acumulado a la deuda de este pago.
/// Devuelve `true` si la operación fue exitosa.
// En AdvancedOptionsViewModel.dart

Future<bool> aplicarSaldoFavor(double montoAAplicar) async {
  _setSaving(true);

  // IMPORTANTE: Ya no abortamos si los IDs son nulos.
  // La lógica del servidor los espera así.

  // ==========================================================
  // <<< LOGS DE DEPURACIÓN (AHORA SÍ SE EJECUTARÁN) >>>
  // ==========================================================
  AppLogger.log("🚀 INTENTANDO APLICAR SALDO A FAVOR (Permitiendo IDs nulos) 🚀");
  AppLogger.log("  - Semana del Pago: ${_pago.semana}");
  AppLogger.log("  - Monto a Aplicar: $montoAAplicar");
  AppLogger.log("  - ID Crédito: $_idCredito");
  AppLogger.log("  - ID Pagos Detalles: ${_pago.idpagosdetalles}"); // <-- Podría ser null
  AppLogger.log("  - ID Fechas Pago: ${_pago.idfechaspagos}");
  AppLogger.log("  - ID Pagos (Principal): ${_pago.idpagos}"); // <-- Podría ser null
  AppLogger.log("  - Monto a Depositar (cuota semanal): ${_pago.capitalMasInteres}");
  AppLogger.log("=================================================");
  
  try {
    // La llamada al servicio AHORA SÍ se ejecutará
    final response = await _pagoService.aplicarSaldoAFavor(
      idCredito: _idCredito,
      // NOTA: Tu servicio debe aceptar valores nulos para estos parámetros.
      // Si el método _pagoService.aplicarSaldoAFavor requiere strings no nulos (String!),
      // tendrás que pasar un string vacío '' o ajustar la firma del método.
      // Asumiremos que acepta nulos (String?).
      idPagosDetalles: _pago.idpagosdetalles, 
      idFechasPago: _pago.idfechaspagos!, // Este probablemente sí sea requerido siempre
      monto: montoAAplicar,
      idPagos: _pago.idpagos,
      montoADepositar: _pago.capitalMasInteres,
    );

    // ==========================================================
    // <<< ESTA ES LA RESPUESTA QUE NECESITAMOS VER AHORA >>>
    // ==========================================================
    AppLogger.log("✅ RESPUESTA DEL SERVICIO 'aplicarSaldoAFavor' ✅");
    AppLogger.log("  - Éxito: ${response.success}");
    if (!response.success && response.error != null) {
      AppLogger.log("  - Mensaje de Error del Servidor: ${response.error}");
    }
    AppLogger.log("=================================================");
      
    if (response.success) {
      onDataChanged();
    }

    _setSaving(false);
    return response.success;
    
  } catch (e, stackTrace) {
    AppLogger.log("🚨 EXCEPCIÓN INESPERADA al llamar a aplicarSaldoAFavor 🚨");
    AppLogger.log("  - Error: $e");
    AppLogger.log("  - StackTrace: $stackTrace");
    AppLogger.log("=================================================");
    _setSaving(false);
    return false;
  }
}



  // +++ AÑADE ESTE NUEVO GETTER AQUÍ +++
  /// Verifica si el moratorio manual ya fue registrado y cubierto en su totalidad.
  bool get moratorioManualEstaPagado {
    // Si no hay información de moratorios pagados, no puede estar pagado.
    if (_pago.pagosMoratorios.isEmpty) {
      return false;
    }

    // Accedemos al primer (y usualmente único) registro del moratorio de la semana.
    final moratorioData = _pago.pagosMoratorios.first;

    // Extraemos los valores de forma segura.
    final moratorioEditable = moratorioData['moratorioEditable'] as String? ?? 'No';
    final sumaMoratorios = (moratorioData['sumaMoratorios'] as num?)?.toDouble() ?? 0.0;
    final moratorioAPagar = (moratorioData['moratorioAPagar'] as num?)?.toDouble() ?? 0.0;

    // La condición es: es editable, el monto es mayor a cero y ya se pagó por completo.
    return moratorioEditable == 'Si' &&
           sumaMoratorios > 0 &&
           sumaMoratorios == moratorioAPagar;
  }
  // +++ FIN DEL CÓDIGO A AÑADIR +++

  // ---------------------------------------------------------------------------
  // --- HELPERS PRIVADOS ---
  // ---------------------------------------------------------------------------

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  void _setDeleting(bool value) {
    _isDeleting = value;
    notifyListeners();
  }


  @override
  void dispose() {
    // <<< AÑADIR >>>
    moratorioEditableController.dispose();
    // <<< FIN DE AÑADIR >>>
    super.dispose();
  }

}