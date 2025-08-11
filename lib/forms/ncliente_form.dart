import 'dart:async';

import 'package:finora_app/models/clientes.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/cliente_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_logger.dart';


// 1. Se cambió el nombre del Widget para mayor claridad.
class nClienteForm extends StatefulWidget {
  final VoidCallback? onClienteAgregado;

  // 2. Se eliminaron los parámetros 'onClienteEditado' y 'idCliente'.
  const nClienteForm({super.key, this.onClienteAgregado});

  @override
  State<nClienteForm> createState() => _nClienteFormState();
}

class _nClienteFormState extends State<nClienteForm>
    with SingleTickerProviderStateMixin {
  //region Controladores y Variables de Estado
  final TextEditingController apellidoPController = TextEditingController();
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController apellidoMController = TextEditingController();
  final TextEditingController calleController = TextEditingController();
  final TextEditingController entreCalleController = TextEditingController();
  final TextEditingController coloniaController = TextEditingController();
  final TextEditingController cpController = TextEditingController();
  final TextEditingController nExtController = TextEditingController();
  final TextEditingController nIntController = TextEditingController();
  final TextEditingController estadoController = TextEditingController();
  final TextEditingController municipioController = TextEditingController();
  final TextEditingController curpController = TextEditingController();
  final TextEditingController claveElectorController = TextEditingController();
  final TextEditingController _claveInterbancariaController =
      TextEditingController();
  final TextEditingController rfcController = TextEditingController();
  final TextEditingController tiempoViviendoController =
      TextEditingController();
  final TextEditingController emailClientecontroller = TextEditingController();
  final TextEditingController telefonoClienteController =
      TextEditingController();
  final TextEditingController nombrePropietarioController =
      TextEditingController();
  final TextEditingController parentescoPropietarioController =
      TextEditingController();
  final TextEditingController nombrePropietarioRefController =
      TextEditingController();
  final TextEditingController parentescoRefPropController =
      TextEditingController();
  final TextEditingController ocupacionController = TextEditingController();
  final TextEditingController depEconomicosController = TextEditingController();
  final TextEditingController nombreConyugeController = TextEditingController();
  final TextEditingController telefonoConyugeController =
      TextEditingController();
  final TextEditingController ocupacionConyugeController =
      TextEditingController();
  final TextEditingController _numCuentaController = TextEditingController();
  final TextEditingController _numTarjetaController = TextEditingController();
  final _fechaController = TextEditingController();

  String? selectedSexo;
  String? selectedECivil;
  String? selectedTipoCliente;
  DateTime? selectedDate;
  String? selectedTipoDomicilio;
  String? selectedTipoDomicilioRef;
  String? _nombreBanco;

  // 3. Se eliminaron las variables innecesarias para "agregar"
  // (isEditing, originalData, ids de registros existentes, etc.)
  bool _isLoading = false;
  String? _clienteIdCreado; // Para manejar la limpieza en caso de error
  bool _noCuentaBancaria = false;

  final List<String> sexos = ['Masculino', 'Femenino'];
  final List<String> estadosCiviles = [
    'Soltero',
    'Casado',
    'Divorciado',
    'Viudo',
    'Unión Libre',
  ];
  final List<String> tiposClientes = [
    'Asalariado',
    'Independiente',
    'Comerciante',
    'Jubilado',
  ];
  List<String> tiposIngresoEgreso = [
    'Actividad economica',
    'Actividad Laboral',
    'Credito con otras financieras',
    'Aportaciones del esposo',
    'Egreso',
    'Otras aportaciones',
  ];
  final List<String> _bancos = [
    "BBVA",
    "Santander",
    "Banorte",
    "HSBC",
    "Banamex",
    "Scotiabank",
    "Bancoppel",
    "Banco Azteca",
    "Inbursa",
  ];
  Map<String, int> tiposIngresoEgresoIds = {
    'Actividad economica': 1,
    'Actividad Laboral': 2,
    'Credito con otras financieras': 3,
    'Aportaciones del esposo': 4,
    'Otras aportaciones': 5,
    'Egreso': 6,
  };
  final List<String> tiposDomicilio = [
    'Propio',
    'Familiar',
    'Rentado',
    'Prestado',
  ];

  final List<Map<String, dynamic>> ingresosEgresos = [];
  List<Map<String, dynamic>> referencias = [];

  late TabController _tabController;
  int _currentIndex = 0;

  final GlobalKey<FormState> _personalFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _cuentaBancariaFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _ingresosEgresosFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _referenciasFormKey = GlobalKey<FormState>();
  //endregion

  // Instancia de tus servicios.
  final ClienteService _clienteService = ClienteService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });

    // 4. Lógica de 'initState' simplificada. Ya no necesita verificar si es edición.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.setContext(context);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose de todos los controladores
    nombresController.dispose();
    apellidoPController.dispose();
    apellidoMController.dispose();
    calleController.dispose();
    entreCalleController.dispose();
    coloniaController.dispose();
    cpController.dispose();
    nExtController.dispose();
    nIntController.dispose();
    estadoController.dispose();
    municipioController.dispose();
    curpController.dispose();
    claveElectorController.dispose();
    _claveInterbancariaController.dispose();
    rfcController.dispose();
    tiempoViviendoController.dispose();
    emailClientecontroller.dispose();
    telefonoClienteController.dispose();
    nombrePropietarioController.dispose();
    parentescoPropietarioController.dispose();
    nombrePropietarioRefController.dispose();
    parentescoRefPropController.dispose();
    ocupacionController.dispose();
    depEconomicosController.dispose();
    nombreConyugeController.dispose();
    telefonoConyugeController.dispose();
    ocupacionConyugeController.dispose();
    _numCuentaController.dispose();
    _numTarjetaController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  //region Lógica de Datos (API Calls)

  // 5. Se han eliminado los métodos: fetchClienteData, sendEditedData, etc.
  // Solo se conserva la lógica para AGREGAR.

  /// Orquesta la creación de un nuevo cliente y todos sus datos asociados.
  Future<void> _agregarCliente() async {
    // Validar el formulario actual antes de intentar guardar todo.
    if (!_validarFormularioActual() || referencias.isEmpty) {
      _showErrorDialog(
        "Datos Faltantes",
        "Asegúrate de haber completado todos los campos requeridos en todas las pestañas y de haber agregado al menos una referencia.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _clienteIdCreado = null;
    });

    try {
      // --- PASO 1: Crear los objetos del modelo a partir de los controladores ---
      final clienteInfo = ClienteInfo(
        tipoCliente: selectedTipoCliente ?? "",
        ocupacion: ocupacionController.text,
        nombres: nombresController.text,
        apellidoP: apellidoPController.text,
        apellidoM: apellidoMController.text,
        fechaNac: selectedDate,
        sexo: selectedSexo ?? "",
        telefono: telefonoClienteController.text,
        eCivil: selectedECivil ?? "",
        email: emailClientecontroller.text,
        dependientesEconomicos: int.tryParse(depEconomicosController.text) ?? 0,
        nombreConyuge: nombreConyugeController.text,
        telefonoConyuge: telefonoConyugeController.text,
        ocupacionConyuge: ocupacionConyugeController.text,
      );

      final cuentaBanco = CuentaBanco(
        nombreBanco: _nombreBanco ?? "",
        numCuenta: _numCuentaController.text,
        numTarjeta: _numTarjetaController.text,
        clbIntBanc: _claveInterbancariaController.text,
      );

      final domicilio = Domicilio(
        tipoDomicilio: selectedTipoDomicilio ?? "",
        nombrePropietario: nombrePropietarioController.text,
        parentesco: parentescoPropietarioController.text,
        calle: calleController.text,
        nExt: nExtController.text,
        nInt: nIntController.text,
        entreCalle: entreCalleController.text,
        colonia: coloniaController.text,
        cp: cpController.text,
        estado: estadoController.text,
        municipio: municipioController.text,
        tiempoViviendo: tiempoViviendoController.text,
      );

      final datosAdicionales = DatosAdicionales(
        curp: curpController.text,
        rfc: rfcController.text,
        clvElector: claveElectorController.text,
      );

      // CÓDIGO CORREGIDO
      final listaIngresos =
          ingresosEgresos
              .map(
                (item) => IngresoEgreso(
                  // Usa el mapa para obtener el ID numérico
                  idinfo: tiposIngresoEgresoIds[item['tipo_info']] ?? 0,
                  // Usa directamente el valor de 'tipo_info' que ya es un String
                  tipo_info: item['tipo_info'] ?? "", // <- Correcto
                  aniosActividad: item['años_actividad']?.toString() ?? '0',
                  descripcion: item['descripcion'] ?? "",
                  montoSemanal: item['monto_semanal']?.toString() ?? '0',
                ),
              )
              .toList();

      final listaReferencias =
          referencias
              .map(
                (ref) => Referencia(
                  nombres: ref['nombresRef'] ?? "",
                  apellidoP: ref['apellidoPRef'] ?? "",
                  apellidoM: ref['apellidoMRef'],
                  parentesco: ref['parentescoRef'] ?? "",
                  telefono: ref['telefonoRef'] ?? "",
                  tiempoConocer: ref['tiempoConocerRef'] ?? "",
                  tipoDomicilio: ref['tipoDomicilioRef'],
                  nombrePropietario: ref['nombrePropietarioRef'],
                  parentescoRefProp: ref['parentescoRefProp'],
                  calle: ref['calleRef'],
                  nExt: ref['nExtRef'],
                  nInt: ref['nIntRef'],
                  entreCalle: ref['entreCalleRef'],
                  colonia: ref['coloniaRef'],
                  cp: ref['cpRef'],
                  estado: ref['estadoRef'],
                  municipio: ref['municipioRef'],
                  tiempoViviendo: ref['tiempoViviendoRef'],
                ),
              )
              .toList();

      // --- PASO 2: Orquestar las llamadas a la API a través del Service ---
      final clienteResponse = await _clienteService.crearCliente(clienteInfo);
      if (!clienteResponse.success || clienteResponse.data == null) {
        return; // ApiService ya mostró el error
      }

      _clienteIdCreado = clienteResponse.data!["idclientes"];
      if (_clienteIdCreado == null || _clienteIdCreado!.isEmpty) {
        _apiService.showErrorDialog(
          "El servidor no devolvió un ID de cliente válido.",
          title: "Error Crítico",
        );
        return;
      }
      AppLogger.log("✅ Cliente creado con ID: $_clienteIdCreado");

      final List<Future<ApiResponse<dynamic>>> futureTasks = [
        _clienteService.crearCuentaBanco(cuentaBanco, _clienteIdCreado!),
        _clienteService.crearDomicilio(domicilio, _clienteIdCreado!),
        _clienteService.crearDatosAdicionales(
          datosAdicionales,
          _clienteIdCreado!,
        ),
      ];

      if (listaIngresos.isNotEmpty) {
        futureTasks.add(
          _clienteService.crearIngresos(listaIngresos, _clienteIdCreado!),
        );
      }
      if (listaReferencias.isNotEmpty) {
        futureTasks.add(
          _clienteService.crearReferencias(listaReferencias, _clienteIdCreado!),
        );
      }

      final results = await Future.wait(futureTasks);
      final bool allSucceeded = results.every((response) => response.success);

      if (!allSucceeded) {
        print(
          "❌ Falla en la creación de datos secundarios para el cliente $_clienteIdCreado.",
        );
        _mostrarDialogoDeErrorParcial();
        return;
      }

      // --- PASO 3: Éxito total ---
      AppLogger.log("🎉 Cliente y todos sus datos asociados creados exitosamente.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cliente agregado correctamente',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onClienteAgregado?.call();
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      AppLogger.log("🔥 Error catastrófico en _agregarCliente: $e");
      AppLogger.log(stackTrace);
      if (mounted) {
        _apiService.showErrorDialog(
          "Ocurrió un error inesperado. Detalles: ${e.toString()}",
          title: "Error de Aplicación",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarDialogoDeErrorParcial() {
    final mensaje =
        'Se creó la ficha del cliente con ID: $_clienteIdCreado, pero ocurrió un error al guardar algunos de sus datos (domicilio, referencias, etc.).\n\nPor favor, vaya a la sección de "Editar Cliente" para completar la información faltante.';

    _apiService.showErrorDialog(mensaje, title: 'Registro Incompleto');
  }
  //endregion

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    // El widget raíz ahora es una Card para darle el aspecto de un BottomSheet
    return Card(
      margin: EdgeInsets.zero, // El margen se controla desde el lanzador
      clipBehavior:
          Clip.antiAlias, // Asegura que el contenido respete los bordes redondeados
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      color: colors.backgroundPrimary,
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // --- NUEVO ENCABEZADO DEL DIÁLOGO ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      children: [
                        // Pequeña barra para indicar que se puede arrastrar
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Título que reemplaza al AppBar
                        Text(
                          'Agregar Cliente',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- WIDGETS ORIGINALES (TabBar y TabBarView) ---
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      tabs: const [
                        Tab(text: 'Personal'),
                        Tab(text: 'Cuenta'),
                        Tab(text: 'Ingresos'),
                        Tab(text: 'Referencias'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Aquí usas tu nuevo widget responsivo, ¡lo cual es perfecto!
                        _buildPaginaPersonalResponsiva(),
                        _paginaCuentaBancariaMobile(),
                        _paginaIngresosEgresosMobile(),
                        _paginaReferenciasMobile(),
                      ],
                    ),
                  ),
                  // Los botones de navegación se mantienen igual
                  _buildNavigationButtons(),
                ],
              ),
    );
  }

  /// 1. Widget principal que decide qué layout mostrar (móvil o desktop).
  Widget _buildPaginaPersonalResponsiva() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Definimos un punto de quiebre. Si el ancho es mayor a 768, usamos el layout de escritorio.
        const double desktopBreakpoint = 768.0;

        if (constraints.maxWidth < desktopBreakpoint) {
          // Pantalla estrecha: Muestra el layout original de móvil.
          return _paginaInfoPersonalMobile();
        } else {
          // Pantalla ancha: Muestra el nuevo layout de escritorio.
          return _paginaInfoPersonalDesktop();
        }
      },
    );
  }

  /// 2. El NUEVO layout para pantallas de escritorio (dos columnas).
  Widget _paginaInfoPersonalDesktop() {
    const double verticalSpacing = 16.0;
    const double horizontalSpacing = 16.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Form(
        key: _personalFormKey,
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Alinea las columnas arriba
          children: [
            // --- COLUMNA IZQUIERDA ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Información Básica'),
                  _buildTextField(
                    controller: nombresController,
                    label: 'Nombres',
                    icon: Icons.person,
                    validator:
                        (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: apellidoPController,
                    label: 'Apellido Paterno',
                    icon: Icons.person_outline,
                    validator:
                        (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: apellidoMController,
                    label: 'Apellido Materno',
                    icon: Icons.person_outline,
                    validator:
                        (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildDropdown(
                    value: selectedTipoCliente,
                    hint: 'Tipo de Cliente',
                    items: tiposClientes,
                    onChanged: (v) => setState(() => selectedTipoCliente = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildDropdown(
                    value: selectedSexo,
                    hint: 'Sexo',
                    items: sexos,
                    onChanged: (v) => setState(() => selectedSexo = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: ocupacionController,
                    label: 'Ocupación',
                    icon: Icons.work,
                    validator:
                        (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: depEconomicosController,
                    label: 'Dependientes económicos',
                    icon: Icons.family_restroom,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: telefonoClienteController,
                    label: 'Teléfono',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator:
                        (v) =>
                            (v == null || v.length != 10)
                                ? 'Teléfono de 10 dígitos'
                                : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: emailClientecontroller,
                    label: 'Correo electrónico',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildDropdown(
                    value: selectedECivil,
                    hint: 'Estado Civil',
                    items: estadosCiviles,
                    onChanged: (v) => setState(() => selectedECivil = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildFechaNacimientoField(),

                  // REFACTOR: Usamos el widget extraído para los campos del cónyuge
                  _buildCamposConyuge(verticalSpacing: verticalSpacing),
                ],
              ),
            ),
            const SizedBox(width: horizontalSpacing), // Espacio entre columnas
            // --- COLUMNA DERECHA ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Domicilio'),
                  _buildDropdown(
                    value: selectedTipoDomicilio,
                    hint: 'Tipo de Domicilio',
                    items: tiposDomicilio,
                    onChanged: (v) => setState(() => selectedTipoDomicilio = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),

                  // REFACTOR: Usamos el widget extraído para los campos del propietario
                  _buildCamposPropietarioDomicilio(
                    verticalSpacing: verticalSpacing,
                  ),

                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: calleController,
                    label: 'Calle',
                    icon: Icons.location_on,
                    validator:
                        (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: nExtController,
                          label: 'No. Ext',
                          icon: Icons.house,
                          keyboardType: TextInputType.number,
                          validator:
                              (v) =>
                                  (v == null || v.isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: nIntController,
                          label: 'No. Int',
                          icon: Icons.house_siding,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: entreCalleController,
                    label: 'Entre Calle',
                    icon: Icons.signpost,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: cpController,
                    label: 'Código Postal',
                    icon: Icons.mail,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    validator:
                        (v) =>
                            (v == null || v.length != 5)
                                ? 'CP de 5 dígitos'
                                : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: tiempoViviendoController,
                    label: 'Tiempo Viviendo (años)',
                    icon: Icons.timelapse,
                    keyboardType: TextInputType.number,
                    validator:
                        (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: coloniaController,
                    label: 'Colonia',
                    icon: Icons.location_city,
                    validator:
                        (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildDropdown(
                    value:
                        estadoController.text.isNotEmpty
                            ? estadoController.text
                            : null,
                    hint: 'Estado',
                    items: ['Guerrero'],
                    onChanged:
                        (v) => setState(() => estadoController.text = v ?? ''),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: municipioController,
                    label: 'Municipio',
                    icon: Icons.map,
                    validator:
                        (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),

                  const SizedBox(
                    height: verticalSpacing * 2,
                  ), // Un poco más de espacio

                  _sectionTitle('Datos Adicionales'),
                  _buildTextField(
                    controller: curpController,
                    label: 'CURP',
                    icon: Icons.account_box,
                    maxLength: 18,
                    validator:
                        (v) =>
                            (v == null || v.length != 18)
                                ? 'CURP de 18 caracteres'
                                : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: rfcController,
                    label: 'RFC',
                    icon: Icons.assignment_ind,
                    maxLength: 13,
                    validator:
                        (v) =>
                            (v == null || (v.length != 12 && v.length != 13))
                                ? 'RFC inválido'
                                : null,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: claveElectorController,
                    label: 'Clave de Elector',
                    icon: Icons.switch_account_rounded,
                    maxLength: 18,
                    validator:
                        (v) =>
                            (v == null || v.length != 18)
                                ? 'Clave de 18 caracteres'
                                : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. WIDGET REFACTORIZADO para los campos del cónyuge
  Widget _buildCamposConyuge({required double verticalSpacing}) {
    if (selectedECivil == 'Casado' || selectedECivil == 'Unión Libre') {
      return Column(
        children: [
          SizedBox(height: verticalSpacing),
          _buildTextField(
            controller: nombreConyugeController,
            label: 'Nombre del Cónyuge',
            icon: Icons.person,
            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
          ),
          SizedBox(height: verticalSpacing),
          _buildTextField(
            controller: telefonoConyugeController,
            label: 'Celular del Cónyuge',
            icon: Icons.phone,
            maxLength: 10,
            keyboardType: TextInputType.phone,
            validator:
                (v) =>
                    (v == null || v.length != 10)
                        ? 'Teléfono de 10 dígitos'
                        : null,
          ),
          SizedBox(height: verticalSpacing),
          _buildTextField(
            controller: ocupacionConyugeController,
            label: 'Ocupación del Cónyuge',
            icon: Icons.work,
            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
          ),
        ],
      );
    }
    return const SizedBox.shrink(); // Retorna un widget vacío si no se cumple la condición
  }

  /// 4. WIDGET REFACTORIZADO para los campos del propietario del domicilio
  Widget _buildCamposPropietarioDomicilio({required double verticalSpacing}) {
    if (selectedTipoDomicilio != null && selectedTipoDomicilio != 'Propio') {
      return Column(
        children: [
          SizedBox(height: verticalSpacing),
          _buildTextField(
            controller: nombrePropietarioController,
            label: 'Nombre del Propietario',
            icon: Icons.person,
            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
          ),
          SizedBox(height: verticalSpacing),
          _buildTextField(
            controller: parentescoPropietarioController,
            label: 'Parentesco',
            icon: Icons.family_restroom,
            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
          ),
        ],
      );
    }
    return const SizedBox.shrink(); // Retorna un widget vacío si no se cumple la condición
  }

  //region Widgets de UI (Sin cambios)
  // Todos tus widgets de UI (_buildNavigationButtons, _pagina...Mobile, diálogos, helpers)
  // pueden permanecer aquí sin cambios, ya que son la estructura del formulario
  // que se usa tanto para agregar como para editar.
  //endregion

  // 7. Lógica del botón de navegación simplificada
  void _handleNextOrSave() {
    FocusScope.of(context).unfocus(); // Ocultar el teclado

    if (!_validarFormularioActual()) {
      _showErrorDialog(
        "Campos Incompletos",
        "Por favor, complete todos los campos requeridos en esta sección.",
      );
      return;
    }

    if (_currentIndex < 3) {
      // Si NO es la última pestaña
      if (_currentIndex == 2 && ingresosEgresos.isEmpty) {
        _showErrorDialog(
          "No se puede avanzar",
          "Por favor, agregue al menos un ingreso o egreso.",
        );
        return;
      }
      _tabController.animateTo(_currentIndex + 1);
    } else {
      // Si ES la última pestaña (Guardar)
      if (referencias.isEmpty) {
        _showErrorDialog(
          "No se puede guardar",
          "Por favor, agregue al menos una referencia.",
        );
        return;
      }
      // La lógica de edición fue removida. Solo se llama a _agregarCliente.
      _agregarCliente();
    }
  }

  // ... (Aquí van todos tus otros widgets de UI sin cambios)
  // _buildNavigationButtons, _paginaInfoPersonalMobile, _paginaCuentaBancariaMobile, etc.
  // No los pego todos para no hacer la respuesta excesivamente larga,
  // pero solo necesitas copiarlos y pegarlos desde tu archivo original.
  // He dejado _handleNextOrSave como ejemplo de la simplificación.

  // PEGA AQUÍ EL RESTO DE TUS WIDGETS DE UI (DESDE _buildNavigationButtons HASTA EL FINAL)
  // ...
  // ... Tu código de widgets de UI ...
  // ...

  // Por completitud, incluyo el resto del código que no cambia:
  Widget _buildNavigationButtons() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              if (_currentIndex > 0) {
                _tabController.animateTo(_currentIndex - 1);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              _currentIndex == 0 ? 'Cancelar' : 'Atrás',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: _handleNextOrSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.backgroundButton,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(_currentIndex == 3 ? 'Guardar' : 'Siguiente'),
          ),
        ],
      ),
    );
  }

  // ... [Y así sucesivamente con todos los demás widgets de UI]
  // El código restante es idéntico al original
  // Pega este código completo para reemplazar tu método _paginaInfoPersonalMobile original.

  Widget _paginaInfoPersonalMobile() {
    const double verticalSpacing = 16.0;

    return SingleChildScrollView(
      // Se quita el padding vertical para que el SingleChildScrollView
      // no interfiera con el padding del contenido.
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Form(
        key: _personalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Sección de Información Básica ---
            _sectionTitle('Información Básica'),
            _buildTextField(
              controller: nombresController,
              label: 'Nombres',
              icon: Icons.person,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: apellidoPController,
              label: 'Apellido Paterno',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: apellidoMController,
              label: 'Apellido Materno',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildDropdown(
              value: selectedTipoCliente,
              hint: 'Tipo de Cliente',
              items: tiposClientes,
              onChanged: (v) => setState(() => selectedTipoCliente = v),
              validator: (v) => v == null ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildDropdown(
              value: selectedSexo,
              hint: 'Sexo',
              items: sexos,
              onChanged: (v) => setState(() => selectedSexo = v),
              validator: (v) => v == null ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: ocupacionController,
              label: 'Ocupación',
              icon: Icons.work,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: depEconomicosController,
              label: 'Dependientes económicos',
              icon: Icons.family_restroom,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: telefonoClienteController,
              label: 'Teléfono',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator:
                  (v) =>
                      (v == null || v.length != 10)
                          ? 'Teléfono de 10 dígitos'
                          : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: emailClientecontroller,
              label: 'Correo electrónico',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: verticalSpacing),
            _buildDropdown(
              value: selectedECivil,
              hint: 'Estado Civil',
              items: estadosCiviles,
              onChanged: (v) => setState(() => selectedECivil = v),
              validator: (v) => v == null ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildFechaNacimientoField(),

            // >> MODIFICACIÓN 1: Se reemplaza el bloque "if" por la llamada al nuevo método.
            _buildCamposConyuge(verticalSpacing: verticalSpacing),

            const SizedBox(height: verticalSpacing),

            // --- Sección de Domicilio ---
            _sectionTitle('Domicilio'),
            _buildDropdown(
              value: selectedTipoDomicilio,
              hint: 'Tipo de Domicilio',
              items: tiposDomicilio,
              onChanged: (v) => setState(() => selectedTipoDomicilio = v),
              validator: (v) => v == null ? 'Requerido' : null,
            ),

            // >> MODIFICACIÓN 2: Se reemplaza el bloque "if" por la llamada al nuevo método.
            _buildCamposPropietarioDomicilio(verticalSpacing: verticalSpacing),

            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: calleController,
              label: 'Calle',
              icon: Icons.location_on,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: nExtController,
                    label: 'No. Ext',
                    icon: Icons.house,
                    keyboardType: TextInputType.number,
                    validator:
                        (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: nIntController,
                    label: 'No. Int',
                    icon: Icons.house_siding,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: entreCalleController,
              label: 'Entre Calle',
              icon: Icons.signpost,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: cpController,
              label: 'Código Postal',
              icon: Icons.mail,
              keyboardType: TextInputType.number,
              maxLength: 5,
              validator:
                  (v) =>
                      (v == null || v.length != 5) ? 'CP de 5 dígitos' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: tiempoViviendoController,
              label: 'Tiempo Viviendo (años)',
              icon: Icons.timelapse,
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: coloniaController,
              label: 'Colonia',
              icon: Icons.location_city,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildDropdown(
              value:
                  estadoController.text.isNotEmpty
                      ? estadoController.text
                      : null,
              hint: 'Estado',
              items: ['Guerrero'],
              onChanged: (v) => setState(() => estadoController.text = v ?? ''),
              validator: (v) => v == null ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: municipioController,
              label: 'Municipio',
              icon: Icons.map,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),

            // --- Sección de Datos Adicionales ---
            _sectionTitle('Datos Adicionales'),
            _buildTextField(
              controller: curpController,
              label: 'CURP',
              icon: Icons.account_box,
              maxLength: 18,
              validator:
                  (v) =>
                      (v == null || v.length != 18)
                          ? 'CURP de 18 caracteres'
                          : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: rfcController,
              label: 'RFC',
              icon: Icons.assignment_ind,
              maxLength: 13,
              validator:
                  (v) =>
                      (v == null || (v.length != 12 && v.length != 13))
                          ? 'RFC inválido'
                          : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: claveElectorController,
              label: 'Clave de Elector',
              icon: Icons.switch_account_rounded,
              maxLength: 18,
              validator:
                  (v) =>
                      (v == null || v.length != 18)
                          ? 'Clave de 18 caracteres'
                          : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginaCuentaBancariaMobile() {
    const double verticalSpacing = 16.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _cuentaBancariaFormKey,
        child: Column(
          children: [
            CheckboxListTile(
              title: const Text("No tiene cuenta bancaria"),
              value: _noCuentaBancaria,
              onChanged: (bool? value) {
                setState(() {
                  _noCuentaBancaria = value ?? false;
                  if (_noCuentaBancaria) {
                    _nombreBanco = null;
                    _numCuentaController.clear();
                    _numTarjetaController.clear();
                    _claveInterbancariaController.clear();
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: verticalSpacing),
            if (!_noCuentaBancaria) ...[
              _buildDropdown(
                value:
                    (_nombreBanco != null && _bancos.contains(_nombreBanco))
                        ? _nombreBanco
                        : null,
                hint: 'Seleccione un Banco',
                items: _bancos,
                onChanged: (value) => setState(() => _nombreBanco = value),
                validator: (v) => v == null ? 'Seleccione un banco' : null,
              ),
              if (_nombreBanco == "Santander") ...[
                const SizedBox(height: verticalSpacing),
                _buildTextField(
                  controller: _claveInterbancariaController,
                  label: 'Clave Interbancaria',
                  icon: Icons.security,
                  keyboardType: TextInputType.number,
                  maxLength: 18,
                  validator:
                      (v) =>
                          (v == null || v.length != 18)
                              ? 'Clave de 18 dígitos'
                              : null,
                ),
              ],
              const SizedBox(height: verticalSpacing),
              _buildTextField(
                controller: _numCuentaController,
                label: 'Número de Cuenta',
                icon: Icons.account_balance_wallet,
                keyboardType: TextInputType.number,
                maxLength: 11,
                validator:
                    (v) =>
                        (v == null || v.length != 11)
                            ? 'Cuenta de 11 dígitos'
                            : null,
              ),
              const SizedBox(height: verticalSpacing),
              _buildTextField(
                controller: _numTarjetaController,
                label: 'Número de Tarjeta',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                maxLength: 16,
                validator:
                    (v) =>
                        (v == null || v.length != 16)
                            ? 'Tarjeta de 16 dígitos'
                            : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paginaIngresosEgresosMobile() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    return Form(
      key: _ingresosEgresosFormKey,
      child: Column(
        children: [
          Expanded(
            child:
                ingresosEgresos.isEmpty
                    ? const Center(
                      child: Text(
                        'No hay ingresos o egresos agregados.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: ingresosEgresos.length,
                      itemBuilder: (context, index) {
                        final item = ingresosEgresos[index];
                        return Card(
                          color: colors.backgroundCard,
                          surfaceTintColor: colors.backgroundCard,
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              item['descripcion'] ?? 'Sin descripción',
                            ),
                            subtitle: Text(
                              '${item['tipo_info'] ?? 'N/A'} - \$${item['monto_semanal'] ?? '0'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed:
                                      () => _mostrarDialogIngresoEgresoMobile(
                                        index: index,
                                        item: item,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () => ingresosEgresos.removeAt(index),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Añadir Ingreso/Egreso'),
              onPressed: () => _mostrarDialogIngresoEgresoMobile(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: colors.backgroundButton,
                foregroundColor: colors.whiteWhite,
                iconColor: colors.whiteWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paginaReferenciasMobile() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    return Form(
      key: _referenciasFormKey,
      child: Column(
        children: [
          Expanded(
            child:
                referencias.isEmpty
                    ? const Center(
                      child: Text(
                        'No hay referencias agregadas.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: referencias.length,
                      itemBuilder: (context, index) {
                        final ref = referencias[index];
                        return Card(
                          color: colors.backgroundCard,
                          surfaceTintColor: colors.backgroundCard,
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              '${ref['nombresRef'] ?? ''} ${ref['apellidoPRef'] ?? ''}',
                            ),
                            subtitle: Text(
                              'Tel: ${ref['telefonoRef'] ?? 'N/A'} - Parentesco: ${ref['parentescoRef'] ?? 'N/A'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed:
                                      () => _mostrarDialogReferenciaMobile(
                                        index: index,
                                        item: ref,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () => referencias.removeAt(index),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Añadir Referencia'),
              onPressed: () => _mostrarDialogReferenciaMobile(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: colors.backgroundButton,
                foregroundColor: colors.whiteWhite,
                iconColor: colors.whiteWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogIngresoEgresoMobile({
    int? index,
    Map<String, dynamic>? item,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;
    final formKey = GlobalKey<FormState>();

    String? selectedTipo = item?['tipo_info'];
    final descripcionController = TextEditingController(
      text: item?['descripcion'] ?? '',
    );
    final montoController = TextEditingController(
      text: item?['monto_semanal']?.toString() ?? '',
    );
    final anosenActividadController = TextEditingController(
      text: item?['años_actividad']?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return SizedBox(
              //height: MediaQuery.of(context).size.height * 0.91,
              child: Card(
                margin: EdgeInsets.zero,
                color: colors.backgroundPrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.0),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 0,
                    left: 16,
                    right: 16,
                    bottom: 50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 30),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        index == null
                            ? 'Nuevo Ingreso/Egreso'
                            : 'Editar Ingreso/Egreso',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('Información del Ingreso/Egreso'),
                                const SizedBox(height: 16),
                                _buildDropdown(
                                  value: selectedTipo,
                                  hint: 'Tipo',
                                  items:
                                      tiposIngresoEgreso
                                          .where((t) => t != 'No asignado')
                                          .toList(),
                                  onChanged:
                                      (v) => dialogSetState(
                                        () => selectedTipo = v,
                                      ),
                                  validator:
                                      (v) => v == null ? 'Requerido' : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: descripcionController,
                                  label: 'Descripción',
                                  icon: Icons.description,
                                  validator:
                                      (v) =>
                                          (v == null || v.isEmpty)
                                              ? 'Requerido'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: montoController,
                                  label: 'Monto Semanal',
                                  icon: Icons.attach_money,
                                  keyboardType: TextInputType.number,
                                  validator:
                                      (v) =>
                                          (v == null || v.isEmpty)
                                              ? 'Requerido'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: anosenActividadController,
                                  label: 'Años en Actividad',
                                  icon: Icons.timelapse,
                                  keyboardType: TextInputType.number,
                                  validator:
                                      (v) =>
                                          (v == null || v.isEmpty)
                                              ? 'Requerido'
                                              : null,
                                ),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: colors.backgroundPrimary,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: colors.textSecondary,
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.brandPrimary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  final nuevoItem = {
                                    'tipo_info': selectedTipo,
                                    'descripcion': descripcionController.text,
                                    'monto_semanal': montoController.text,
                                    'años_actividad':
                                        anosenActividadController.text,
                                  };
                                  setState(() {
                                    if (index == null) {
                                      ingresosEgresos.add(nuevoItem);
                                    } else {
                                      ingresosEgresos[index] = nuevoItem;
                                    }
                                  });
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogReferenciaMobile({
    int? index,
    Map<String, dynamic>? item,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;
    final formKey = GlobalKey<FormState>();

    String? selectedParentesco = item?['parentescoRef'];
    final nombresRefController = TextEditingController(
      text: item?['nombresRef'] ?? '',
    );
    final apellidoPRefController = TextEditingController(
      text: item?['apellidoPRef'] ?? '',
    );
    final apellidoMRefController = TextEditingController(
      text: item?['apellidoMRef'] ?? '',
    );
    final telefonoRefController = TextEditingController(
      text: item?['telefonoRef'] ?? '',
    );
    final tiempoConocerRefController = TextEditingController(
      text: item?['tiempoConocerRef'] ?? '',
    );

    String? selectedTipoDomicilioRef = item?['tipoDomicilioRef'];
    final calleRefController = TextEditingController(
      text: item?['calleRef'] ?? '',
    );
    final nombrePropietarioRefController = TextEditingController(
      text: item?['nombrePropietarioRef'] ?? '',
    );
    final parentescoRefPropController = TextEditingController(
      text: item?['parentescoPropRef'] ?? '',
    );
    final nExtRefController = TextEditingController(
      text: item?['nExtRef'] ?? '',
    );
    final nIntRefController = TextEditingController(
      text: item?['nIntRef'] ?? '',
    );
    final entreCalleRefController = TextEditingController(
      text: item?['entreCalleRef'] ?? '',
    );
    final coloniaRefController = TextEditingController(
      text: item?['coloniaRef'] ?? '',
    );
    final cpRefController = TextEditingController(text: item?['cpRef'] ?? '');
    final estadoRefController = TextEditingController(
      text: item?['estadoRef'] ?? 'Guerrero',
    );
    final municipioRefController = TextEditingController(
      text: item?['municipioRef'] ?? '',
    );
    final tiempoViviendoRefController = TextEditingController(
      text: item?['tiempoViviendoRef'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return SizedBox(
              //height: MediaQuery.of(context).size.height * 0.91,
              child: Card(
                margin: EdgeInsets.zero,
                color: colors.backgroundPrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.0),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 0,
                    left: 16,
                    right: 16,
                    bottom: 50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 30),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        index == null
                            ? "Nueva Referencia"
                            : "Editar Referencia",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('Información de la Persona'),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: nombresRefController,
                                  label: 'Nombres',
                                  icon: Icons.person,
                                  validator:
                                      (v) =>
                                          (v == null || v.isEmpty)
                                              ? 'Requerido'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: apellidoPRefController,
                                  label: 'Apellido Paterno',
                                  icon: Icons.person_outline,
                                  validator:
                                      (v) =>
                                          (v == null || v.isEmpty)
                                              ? 'Requerido'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: apellidoMRefController,
                                  label: 'Apellido Materno',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildDropdown(
                                  value: selectedParentesco,
                                  hint: 'Parentesco',
                                  items: [
                                    'Padre',
                                    'Madre',
                                    'Hermano/a',
                                    'Amigo/a',
                                    'Vecino',
                                    'Otro',
                                  ],
                                  onChanged:
                                      (v) => dialogSetState(
                                        () => selectedParentesco = v,
                                      ),
                                  validator:
                                      (v) => v == null ? 'Requerido' : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: telefonoRefController,
                                  label: 'Teléfono',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator:
                                      (v) =>
                                          (v == null || v.length != 10)
                                              ? 'Teléfono de 10 dígitos'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: tiempoConocerRefController,
                                  label: 'Tiempo de Conocer (años)',
                                  icon: Icons.timelapse,
                                  keyboardType: TextInputType.number,
                                  validator:
                                      (v) =>
                                          (v == null || v.isEmpty)
                                              ? 'Requerido'
                                              : null,
                                ),
                                const SizedBox(height: 24),
                                _sectionTitle('Domicilio (Opcional)'),
                                const SizedBox(height: 16),
                                _buildDropdown(
                                  value: selectedTipoDomicilioRef,
                                  hint: 'Tipo Domicilio',
                                  items: tiposDomicilio,
                                  onChanged:
                                      (v) => dialogSetState(
                                        () => selectedTipoDomicilioRef = v,
                                      ),
                                ),
                                if (selectedTipoDomicilioRef != null) ...[
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: calleRefController,
                                    label: 'Calle',
                                    icon: Icons.location_on,
                                  ),
                                  if (selectedTipoDomicilioRef != 'Propio') ...[
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller:
                                          nombrePropietarioRefController,
                                      label: 'Nombre del Propietario',
                                      icon: Icons.person,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: parentescoRefPropController,
                                      label: 'Parentesco con propietario',
                                      icon: Icons.family_restroom,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: nExtRefController,
                                          label: 'No. Ext',
                                          icon: Icons.house,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: nIntRefController,
                                          label: 'No. Int',
                                          icon: Icons.house,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: entreCalleRefController,
                                    label: 'Entre Calle',
                                    icon: Icons.location_on,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: coloniaRefController,
                                          label: 'Colonia',
                                          icon: Icons.location_city,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: cpRefController,
                                          label: 'Código Postal',
                                          icon: Icons.mail,
                                          keyboardType: TextInputType.number,
                                          maxLength: 5,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          validator: (value) {
                                            if (value != null &&
                                                value.isNotEmpty &&
                                                value.length != 5) {
                                              return 'Debe tener 5 dígitos';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDropdown(
                                          value:
                                              estadoRefController
                                                      .text
                                                      .isNotEmpty
                                                  ? estadoRefController.text
                                                  : null,
                                          hint: 'Estado',
                                          items: ['Guerrero'],
                                          onChanged: (value) {
                                            dialogSetState(() {
                                              estadoRefController.text =
                                                  value ?? '';
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: municipioRefController,
                                          label: 'Municipio',
                                          icon: Icons.map,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: tiempoViviendoRefController,
                                    label: 'Tiempo Viviendo',
                                    icon: Icons.timelapse,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: colors.textSecondary,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.brandPrimary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                final nuevaReferencia = {
                                  'nombresRef': nombresRefController.text,
                                  'apellidoPRef': apellidoPRefController.text,
                                  'apellidoMRef': apellidoMRefController.text,
                                  'parentescoRef': selectedParentesco,
                                  'telefonoRef': telefonoRefController.text,
                                  'tiempoConocerRef':
                                      tiempoConocerRefController.text,
                                  'tipoDomicilioRef': selectedTipoDomicilioRef,
                                  'calleRef': calleRefController.text,
                                  'nombrePropietarioRef':
                                      nombrePropietarioRefController.text,
                                  'parentescoPropRef':
                                      parentescoRefPropController.text,
                                  'nExtRef': nExtRefController.text,
                                  'nIntRef': nIntRefController.text,
                                  'entreCalleRef': entreCalleRefController.text,
                                  'coloniaRef': coloniaRefController.text,
                                  'cpRef': cpRefController.text,
                                  'estadoRef': estadoRefController.text,
                                  'municipioRef': municipioRefController.text,
                                  'tiempoViviendoRef':
                                      tiempoViviendoRefController.text,
                                };
                                setState(() {
                                  if (index == null) {
                                    referencias.add(nuevaReferencia);
                                  } else {
                                    referencias[index] = nuevaReferencia;
                                  }
                                });
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Guardar'),
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
      },
    );
  }

  Widget _sectionTitle(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: colors.brandPrimary,
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  bool _validarFormularioActual() {
    switch (_currentIndex) {
      case 0:
        return _personalFormKey.currentState?.validate() ?? false;
      case 1:
        return _cuentaBancariaFormKey.currentState?.validate() ?? false;
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    // Necesitamos usar un StatefulWidget o un State hook para escuchar los cambios
    // del controller y actualizar la UI. La forma más sencilla sin instalar
    // paquetes es convertir el widget que usa _buildTextField en un StatefulWidget,
    // pero para no cambiar toda tu estructura, usaremos un truco con ValueListenableBuilder.

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      // Usamos ValueListenableBuilder para reconstruir solo el TextFormField
      // cuando el texto cambie, y así actualizar el contador.
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength:
                maxLength, // Mantenemos maxLength para el límite de caracteres
            validator: validator,
            inputFormatters: inputFormatters,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14, // <-- AÑADE ESTA LÍNEA
            ),
            // ¡Importante! Ocultamos el contador por defecto para evitar duplicados y espacios raros.
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
              prefixIcon: Icon(icon, color: colors.textSecondary),

              // Esta es la clave de la nueva solución:
              suffixIcon:
                  maxLength != null
                      ? Padding(
                        // Un poco de padding para que no se pegue al borde derecho
                        padding: const EdgeInsets.only(
                          right: 16.0,
                          top: 14.0,
                          bottom: 14.0,
                        ),
                        child: Text(
                          '${value.text.length}/$maxLength',
                          style: TextStyle(
                            color: colors.textSecondary.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      )
                      : null, // Si no hay maxLength, no mostramos nada.
              // Esto es crucial: le decimos a la decoración que no muestre su propio contador.
              counterText: '',

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        items:
            items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        dropdownColor: colors.backgroundCard,
      ),
    );
  }

  Widget _buildFechaNacimientoField() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: _fechaController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Fecha de Nacimiento',
          labelStyle: TextStyle(color: colors.textSecondary),
          prefixIcon: Icon(Icons.calendar_today, color: colors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            locale: const Locale('es', 'ES'),
          );
          if (pickedDate != null) {
            setState(() {
              selectedDate = pickedDate;
              _fechaController.text = DateFormat(
                'dd/MM/yyyy',
              ).format(selectedDate!);
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, seleccione una fecha';
          }
          return null;
        },
        style: TextStyle(color: colors.textPrimary),
      ),
    );
  }
}
