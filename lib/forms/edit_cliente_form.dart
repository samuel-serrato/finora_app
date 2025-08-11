import 'dart:async';
import 'dart:convert';

import 'package:finora_app/models/clientes.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/cliente_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_logger.dart';


class EditarClienteForm extends StatefulWidget {
  final String idCliente;
  final VoidCallback? onClienteEditado;

  const EditarClienteForm({
    super.key,
    required this.idCliente,
    this.onClienteEditado,
  });

  @override
  _EditarClienteFormState createState() => _EditarClienteFormState();
}

class _EditarClienteFormState extends State<EditarClienteForm>
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
  String? _nombreBanco;
  String? idcuantabank;
  int? iddomicilios;
  List<int> idingegrList = [];
  List<int> idreferenciasList = [];
  bool _noCuentaBancaria = false;
  bool _isLoading = true;
  Map<String, dynamic> originalData = {};

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
  final List<String> tiposIngresoEgreso = [
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

  final ClienteService _clienteService = ClienteService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(
      () => setState(() => _currentIndex = _tabController.index),
    );
    fetchClienteData();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _apiService.setContext(context),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    // ... dispose todos los controllers ...
    super.dispose();
  }
  //endregion

  //region Lógica de Datos
  String _formatearFecha(String? fechaStr) {
    if (fechaStr == null || fechaStr.isEmpty) return '';
    try {
      final fecha = DateTime.parse(fechaStr);
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  // En editar_cliente_form.dart

  Future<void> fetchClienteData() async {
    // Aseguramos que el estado de carga se active al inicio.
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Asumimos que getCliente devuelve el primer objeto de la lista [{}].
    // Si devuelve la lista completa, necesitarías hacer: final data = response.data![0];
    final response = await _clienteService.getCliente(widget.idCliente);

    if (!response.success || response.data == null) {
      if (mounted) {
        _apiService.showErrorDialog(
          "Error No se pudieron cargar los datos del cliente. Por favor, inténtelo de nuevo.",
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // Si response.data es la lista `[...]`, debes acceder al primer elemento.
    // Si ya lo extraes en el servicio, este paso no es necesario.
    final data = response.data is List ? response.data![0] : response.data;
    originalData = json.decode(
      json.encode(data),
    ); // Copia para comparar cambios al guardar.

    // Depuración para ver qué claves realmente llegan de la API. ¡Revisa tu consola!
    AppLogger.log("✅ [DEBUG] Keys recibidas de la API: ${data.keys}");

    String mostrarVacioSiNoAsignado(String? valor) {
      if (valor == null || valor == 'No asignado') {
        return '';
      }
      return valor;
    }

    // Usamos 'mounted' para asegurarnos de que el widget todavía existe antes de llamar a setState.
    if (mounted) {
      setState(() {
        // --- 1. Poblar Datos del Nivel Superior (lo que ya funcionaba bien) ---
        nombresController.text = data['nombres'] ?? '';
        apellidoPController.text = data['apellidoP'] ?? '';
        apellidoMController.text = data['apellidoM'] ?? '';
        telefonoClienteController.text = data['telefono'] ?? '';
        emailClientecontroller.text = mostrarVacioSiNoAsignado(data['email']);

        ocupacionController.text = data['ocupacion'] ?? '';
        // El valor puede ser String o num, toString() lo maneja.
        depEconomicosController.text =
            (data['dependientes_economicos'] ?? 0).toString();
        nombreConyugeController.text = data['nombreConyuge'] ?? '';
        telefonoConyugeController.text = data['telefonoConyuge'] ?? '';
        ocupacionConyugeController.text = data['ocupacionConyuge'] ?? '';
        selectedTipoCliente = data['tipo_cliente'];
        selectedSexo = data['sexo'];
        selectedECivil = data['eCivil'];
        if (data['fechaNac'] != null && data['fechaNac'].isNotEmpty) {
          try {
            selectedDate = DateTime.parse(data['fechaNac']);
            _fechaController.text = _formatearFecha(data['fechaNac']);
          } catch (e) {
            print(
              "⚠️ Error al parsear la fecha: ${data['fechaNac']}. Error: $e",
            );
          }
        }

        // --- 2. Poblar Datos de la lista 'adicionales' ---
        if (data.containsKey('adicionales') &&
            data['adicionales'] is List &&
            (data['adicionales'] as List).isNotEmpty) {
          final adicionalesData = data['adicionales'][0];
          curpController.text = adicionalesData['curp'] ?? '';
          rfcController.text = adicionalesData['rfc'] ?? '';
          claveElectorController.text = adicionalesData['clvElector'] ?? '';
        }

        // --- 3. Poblar Datos de la lista 'domicilios' (CORREGIDO) ---
        if (data.containsKey('domicilios') &&
            data['domicilios'] is List &&
            (data['domicilios'] as List).isNotEmpty) {
          final domicilioData = data['domicilios'][0];
          iddomicilios = domicilioData['iddomicilios'];
          selectedTipoDomicilio = domicilioData['tipo_domicilio'];
          nombrePropietarioController.text =
              domicilioData['nombre_propietario'] ?? '';
          parentescoPropietarioController.text =
              domicilioData['parentesco'] ?? '';
          calleController.text = domicilioData['calle'] ?? '';
          nExtController.text = domicilioData['nExt']?.toString() ?? '';
          nIntController.text = domicilioData['nInt']?.toString() ?? '';
          entreCalleController.text = domicilioData['entreCalle'] ?? '';
          coloniaController.text = domicilioData['colonia'] ?? '';
          cpController.text = domicilioData['cp'] ?? '';
          estadoController.text = domicilioData['estado'] ?? 'Guerrero';
          municipioController.text = domicilioData['municipio'] ?? '';
          tiempoViviendoController.text =
              domicilioData['tiempoViviendo']?.toString() ?? '';
        }

        // --- 4. Poblar Datos de la lista 'cuentabanco' ---
        if (data.containsKey('cuentabanco') &&
            data['cuentabanco'] is List &&
            (data['cuentabanco'] as List).isNotEmpty) {
          final cuentaData = data['cuentabanco'][0];
          idcuantabank = cuentaData['idcuantabank'].toString();
          _nombreBanco = cuentaData['nombreBanco'];
          _numCuentaController.text = cuentaData['numCuenta'] ?? '';
          _numTarjetaController.text = cuentaData['numTarjeta'] ?? '';
          _claveInterbancariaController.text = cuentaData['clbIntBanc'] ?? '';
          _noCuentaBancaria = false;
        } else {
          _noCuentaBancaria = true;
        }

        // --- 5. Poblar la lista 'ingresos_egresos' ---
        if (data.containsKey('ingresos_egresos') &&
            data['ingresos_egresos'] is List) {
          ingresosEgresos.clear();
          idingegrList.clear();
          for (var item in (data['ingresos_egresos'] as List)) {
            ingresosEgresos.add(Map<String, dynamic>.from(item));
            idingegrList.add(item['idingegr']);
          }
        }

        // --- 6. Poblar la lista 'referencias' (CORREGIDO) ---
        if (data.containsKey('referencias') && data['referencias'] is List) {
          referencias.clear();
          idreferenciasList.clear();

          // Iteramos sobre cada objeto de referencia que viene de la API
          for (var apiRef in (data['referencias'] as List)) {
            // 1. Creamos un nuevo mapa (`uiRef`) con las claves que la UI espera.
            //    Esto "traduce" los datos de la API al formato de la UI.
            final Map<String, dynamic> uiRef = {
              // Clave UI       <-- Clave API
              'nombresRef': apiRef['nombres'],
              'apellidoPRef': apiRef['apellidoP'],
              'apellidoMRef': apiRef['apellidoM'],
              'telefonoRef': apiRef['telefono'],
              'parentescoRef':
                  apiRef['parentescoRefProp'], // Ojo: la API usa 'parentescoRefProp'
              'tiempoConocerRef':
                  apiRef['tiempoCo']?.toString(), // La API usa 'tiempoCo'
              'idreferencias': apiRef['idreferencias'], // Mantenemos el ID
            };

            // 2. Manejamos el domicilio de la referencia, si es que existe.
            if (apiRef.containsKey('domicilio_ref') &&
                apiRef['domicilio_ref'] is List &&
                (apiRef['domicilio_ref'] as List).isNotEmpty) {
              final domicilioData = apiRef['domicilio_ref'][0];

              // Verificamos si el domicilio tiene datos reales o es solo "No asignado"
              if (domicilioData['datos'] != 'No asignado' &&
                  domicilioData.length > 1) {
                // Si hay datos, los agregamos al mapa `uiRef` con las claves correctas.
                // Aquí también hacemos un mapeo, por si las claves del domicilio de la referencia
                // son diferentes a las que espera el diálogo.
                uiRef.addAll({
                  // Clave UI                <-- Clave API del domicilio
                  'tipoDomicilioRef': domicilioData['tipo_domicilio'],
                  'calleRef': domicilioData['calle'],
                  'nombrePropietarioRef': domicilioData['nombre_propietario'],
                  'parentescoPropRef':
                      domicilioData['parentesco'], // Ojo a esta clave
                  'nExtRef': domicilioData['nExt']?.toString(),
                  'nIntRef': domicilioData['nInt']?.toString(),
                  'entreCalleRef': domicilioData['entreCalle'],
                  'coloniaRef': domicilioData['colonia'],
                  'cpRef': domicilioData['cp'],
                  'estadoRef': domicilioData['estado'],
                  'municipioRef': domicilioData['municipio'],
                  'tiempoViviendoRef':
                      domicilioData['tiempoViviendo']?.toString(),
                });
              }
            }

            // 3. Agregamos el mapa ya formateado (`uiRef`) a nuestra lista `referencias`.
            referencias.add(uiRef);
            // Y guardamos el ID para futuras operaciones.
            idreferenciasList.add(apiRef['idreferencias']);
          }
        }

        // Finalmente, se desactiva el estado de carga para mostrar el formulario.
        _isLoading = false;
      });
    }
  }

  // ... (dentro de la clase _EditarClienteFormState)

  Future<void> sendEditedData() async {
    setState(() {
      _isLoading = true;
    });

    // Lista para recolectar errores y mostrarlos al final
    List<String> errorMessages = [];

    try {
      // --- 1. ACTUALIZAR INFORMACIÓN PERSONAL (CLIENTE) ---
      final clienteInfo = ClienteInfo(
        nombres: nombresController.text,
        apellidoP: apellidoPController.text,
        apellidoM: apellidoMController.text,
        tipoCliente: selectedTipoCliente!,
        sexo: selectedSexo!,
        ocupacion: ocupacionController.text,
        dependientesEconomicos: int.tryParse(depEconomicosController.text) ?? 0,
        telefono: telefonoClienteController.text,
        email: emailClientecontroller.text,
        eCivil: selectedECivil!,
        fechaNac: selectedDate,
        nombreConyuge: nombreConyugeController.text,
        telefonoConyuge: telefonoConyugeController.text,
        ocupacionConyuge: ocupacionConyugeController.text,
      );
      final clienteResponse = await _clienteService.actualizarClienteInfo(
        widget.idCliente,
        clienteInfo,
      );
      if (!clienteResponse.success) {
        errorMessages.add(
          "Error al actualizar datos personales: ${clienteResponse.error}",
        );
      }

      // --- 2. ACTUALIZAR DATOS ADICIONALES ---
      final datosAdicionales = DatosAdicionales(
        curp: curpController.text,
        rfc: rfcController.text,
        clvElector: claveElectorController.text,
      );
      final adicionalesResponse = await _clienteService
          .actualizarDatosAdicionales(widget.idCliente, datosAdicionales);
      if (!adicionalesResponse.success) {
        errorMessages.add(
          "Error al actualizar datos adicionales: ${adicionalesResponse.error}",
        );
      }

      // --- 3. ACTUALIZAR DOMICILIO ---
      if (iddomicilios != null) {
        final domicilio = Domicilio(
          tipoDomicilio: selectedTipoDomicilio!,
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
        // CORRECCIÓN: Pasamos el idCliente (widget.idCliente) como primer argumento
        final domicilioResponse = await _clienteService.actualizarDomicilio(
          widget.idCliente,
          iddomicilios!,
          domicilio,
        );
        if (!domicilioResponse.success) {
          // El mensaje de error ahora será más útil si la API devuelve uno
          errorMessages.add(
            "No se logró editar el domicilio con ID ${iddomicilios!}: ${domicilioResponse.error}",
          );
        }
      }

      // --- 4. ACTUALIZAR O CREAR CUENTA BANCARIA (LÓGICA MEJORADA) ---

      // Variable para almacenar el objeto CuentaBanco que se enviará.
      CuentaBanco cuentaParaEnviar;

      if (_noCuentaBancaria) {
        // CASO 1: El usuario marcó "No tiene cuenta bancaria".
        // Creamos un objeto CuentaBanco con todos los campos vacíos.
        // La API debería interpretar esto como "borrar los datos de la cuenta".
        cuentaParaEnviar = CuentaBanco(
          nombreBanco: "", // string vacío
          numCuenta: "", // string vacío
          numTarjeta: "", // string vacío
          clbIntBanc: "", // string vacío
          idclientes: widget.idCliente,
        );
      } else {
        // CASO 2: El usuario SÍ tiene cuenta bancaria.
        // Usamos la lógica que ya tenías para crear el objeto con los datos del formulario.
        cuentaParaEnviar = CuentaBanco(
          nombreBanco: _nombreBanco ?? "", // Usamos "" si el banco es nulo
          numCuenta: _numCuentaController.text,
          numTarjeta: _numTarjetaController.text,
          clbIntBanc: _claveInterbancariaController.text,
          idclientes: widget.idCliente,
        );
      }

      // Ahora, sin importar el caso, enviamos la petición a la API.
      // Solo nos aseguramos de que exista un idcuantabank, ya que este endpoint es para editar.
      if (idcuantabank != null && idcuantabank!.isNotEmpty) {
        final cuentaResponse = await _clienteService
            .crearOActualizarCuentaBanco(
              widget.idCliente,
              idcuantabank,
              cuentaParaEnviar, // Enviamos el objeto que preparamos
            );

        if (!cuentaResponse.success) {
          errorMessages.add(
            "Error al actualizar la cuenta bancaria: ${cuentaResponse.error}",
          );
        }
      } else if (_noCuentaBancaria) {
        // Si no había cuenta antes y el usuario sigue sin querer una, no hacemos nada.
        // Esto es correcto.
      } else {
        // Si no había cuenta antes pero el usuario AHORA SÍ quiere una,
        // debemos llamar a un método de creación.
        // Tu método `crearOActualizarCuentaBanco` ya debería manejar esto si `idcuantabank` es null.
        final cuentaResponse = await _clienteService.crearOActualizarCuentaBanco(
          widget.idCliente,
          null, // Se pasa null para que el servicio sepa que es una creación
          cuentaParaEnviar,
        );
        if (!cuentaResponse.success) {
          errorMessages.add(
            "Error al crear la nueva cuenta bancaria: ${cuentaResponse.error}",
          );
        }
      }

      // --- 5. ACTUALIZAR INGRESOS ---
      // Preparamos la lista de ingresos con los IDs correspondientes
      final List<Map<String, dynamic>> ingresosPayload = [];
      for (int i = 0; i < ingresosEgresos.length; i++) {
        ingresosPayload.add({
          "idingegr":
              idingegrList.length > i
                  ? idingegrList[i]
                  : null, // Incluir ID si existe
          "idinfo": 1, // Asignar el ID de tipo de info si es necesario
          "años_actividad": ingresosEgresos[i]['años_actividad'],
          "descripcion": ingresosEgresos[i]['descripcion'],
          "monto_semanal": ingresosEgresos[i]['monto_semanal'],
        });
      }
      final ingresosResponse = await _clienteService.actualizarIngresos(
        widget.idCliente,
        ingresosPayload,
      );
      if (!ingresosResponse.success) {
        errorMessages.add(
          "Error al actualizar ingresos: ${ingresosResponse.error}",
        );
      }

      // --- 6. ACTUALIZAR REFERENCIAS ---
      final List<Map<String, dynamic>> referenciasPayload = [];
      for (int i = 0; i < referencias.length; i++) {
        referenciasPayload.add({
          "idreferencias":
              idreferenciasList.length > i ? idreferenciasList[i] : null,
          "nombres": referencias[i]['nombresRef'],
          "apellidoP": referencias[i]['apellidoPRef'],
          "apellidoM": referencias[i]['apellidoMRef'],
          "parentescoRefProp": referencias[i]['parentescoRef'],
          "telefono": referencias[i]['telefonoRef'],
          "tiempoCo": referencias[i]['tiempoConocerRef'],
        });
      }
      final referenciasResponse = await _clienteService.actualizarReferencias(
        widget.idCliente,
        referenciasPayload,
      );
      if (!referenciasResponse.success) {
        errorMessages.add(
          "Error al actualizar referencias: ${referenciasResponse.error}",
        );
      }

      // --- FINALIZACIÓN ---
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (errorMessages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onClienteEditado?.call();
          Navigator.of(context).pop();
        } else {
          _showErrorDialog("Ocurrieron Errores", errorMessages.join("\n\n"));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog("Error Inesperado", e.toString());
      }
    }
  }
  //endregion

  //region UI y Widgets (El resto del código es idéntico)

  // ---- ¡AQUÍ ESTÁ EL CAMBIO PRINCIPAL! ----
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      color: colors.backgroundPrimary,
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // --- INICIO: ENCABEZADO MEJORADO ---
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
                          'Editar Cliente',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- FIN: ENCABEZADO MEJORADO ---

                  // 2. CONTENIDO ORIGINAL DEL FORMULARIO (lo que estaba en el body del Scaffold)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: colors.backgroundCard,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 40,
                      child: IgnorePointer(
                        child: TabBar(
                          controller: _tabController,
                          // ... el resto de la configuración del TabBar
                          indicator: BoxDecoration(
                            color: colors.brandPrimary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: colors.whiteWhite,
                          unselectedLabelColor:
                              themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 2,
                          ),
                          tabs: const [
                            Tab(text: 'Personal'),
                            Tab(text: 'Cuenta'),
                            Tab(text: 'Ingresos'),
                            Tab(text: 'Referencias'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ¡AQUÍ ESTÁ EL CAMBIO!
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

  /// 2. AGREGA este nuevo widget. Decide qué layout mostrar (móvil o desktop).
  Widget _buildPaginaPersonalResponsiva() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mismo punto de quiebre que en el formulario de agregar.
        const double desktopBreakpoint = 768.0;

        if (constraints.maxWidth < desktopBreakpoint) {
          // Pantalla estrecha: Muestra el layout de móvil (ahora refactorizado).
          return _paginaInfoPersonalMobile();
        } else {
          // Pantalla ancha: Muestra el nuevo layout de escritorio.
          return _paginaInfoPersonalDesktop();
        }
      },
    );
  }

  /// 3. AGREGA el layout para pantallas de escritorio (dos columnas).
  /// Es una copia directa del que creaste en `nClienteForm`.
  Widget _paginaInfoPersonalDesktop() {
    const double verticalSpacing = 16.0;
    const double horizontalSpacing = 16.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Form(
        key: _personalFormKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  _buildCamposConyuge(verticalSpacing: verticalSpacing),
                ],
              ),
            ),
            const SizedBox(width: horizontalSpacing),
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
                  _buildCamposPropietarioDomicilio(
                    verticalSpacing: verticalSpacing,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: calleController,
                    label: 'Calle',
                    icon: Icons.location_on,
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
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: tiempoViviendoController,
                    label: 'Tiempo Viviendo (años)',
                    icon: Icons.timelapse,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: coloniaController,
                    label: 'Colonia',
                    icon: Icons.location_city,
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
                  ),
                  const SizedBox(height: verticalSpacing * 2),
                  _sectionTitle('Datos Adicionales'),
                  _buildTextField(
                    controller: curpController,
                    label: 'CURP',
                    icon: Icons.account_box,
                    maxLength: 18,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: rfcController,
                    label: 'RFC',
                    icon: Icons.assignment_ind,
                    maxLength: 13,
                  ),
                  const SizedBox(height: verticalSpacing),
                  _buildTextField(
                    controller: claveElectorController,
                    label: 'Clave de Elector',
                    icon: Icons.switch_account_rounded,
                    maxLength: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. AGREGA los widgets refactorizados para los campos dinámicos.
  /// Son copias directas de `nClienteForm`.
  Widget _buildCamposConyuge({required double verticalSpacing}) {
    if (selectedECivil == 'Casado' || selectedECivil == 'Unión Libre') {
      return Column(
        children: [
          SizedBox(height: verticalSpacing),
          _buildTextField(
            controller: nombreConyugeController,
            label: 'Nombre del Cónyuge',
            icon: Icons.person,
          ),
          SizedBox(height: verticalSpacing),
          _buildTextField(
            controller: telefonoConyugeController,
            label: 'Celular del Cónyuge',
            icon: Icons.phone,
            maxLength: 10,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: verticalSpacing),
          _buildTextField(
            controller: ocupacionConyugeController,
            label: 'Ocupación del Cónyuge',
            icon: Icons.work,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCamposPropietarioDomicilio({required double verticalSpacing}) {
    if (selectedTipoDomicilio != null && selectedTipoDomicilio != 'Propio') {
      return Column(
        children: [
          SizedBox(height: verticalSpacing),
          _buildTextField(
            controller: nombrePropietarioController,
            label: 'Nombre del Propietario',
            icon: Icons.person,
          ),
          SizedBox(height: verticalSpacing),
          _buildTextField(
            controller: parentescoPropietarioController,
            label: 'Parentesco',
            icon: Icons.family_restroom,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  void _handleNextOrSave() {
    FocusScope.of(context).unfocus();
    if (_validarFormularioActual()) {
      if (_currentIndex < 3) {
        _tabController.animateTo(_currentIndex + 1);
      } else {
        if (referencias.isEmpty) {
          _showErrorDialog(
            "No se puede guardar",
            "Por favor, agregue al menos una referencia.",
          );
          return;
        }
        sendEditedData();
      }
    } else {
      _showErrorDialog(
        "Campos Incompletos",
        "Por favor, complete todos los campos requeridos.",
      );
    }
  }

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
            child: Text(_currentIndex == 3 ? 'Guardar Cambios' : 'Siguiente'),
          ),
        ],
      ),
    );
  }

  Widget _paginaInfoPersonalMobile() {
    const double verticalSpacing = 16.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _personalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // >> MODIFICACIÓN: Se reemplaza el bloque "if" por la llamada al nuevo método.
            _buildCamposConyuge(verticalSpacing: verticalSpacing),

            const SizedBox(height: verticalSpacing),
            _sectionTitle('Domicilio'),
            _buildDropdown(
              value: selectedTipoDomicilio,
              hint: 'Tipo de Domicilio',
              items: tiposDomicilio,
              onChanged: (v) => setState(() => selectedTipoDomicilio = v),
              validator: (v) => v == null ? 'Requerido' : null,
            ),

            // >> MODIFICACIÓN: Se reemplaza el bloque "if" por la llamada al nuevo método.
            _buildCamposPropietarioDomicilio(verticalSpacing: verticalSpacing),

            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: calleController,
              label: 'Calle',
              icon: Icons.location_on,
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
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: tiempoViviendoController,
              label: 'Tiempo Viviendo (años)',
              icon: Icons.timelapse,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: coloniaController,
              label: 'Colonia',
              icon: Icons.location_city,
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
            ),
            const SizedBox(height: verticalSpacing),

            _sectionTitle('Datos Adicionales'),
            _buildTextField(
              controller: curpController,
              label: 'CURP',
              icon: Icons.account_box,
              maxLength: 18,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: rfcController,
              label: 'RFC',
              icon: Icons.assignment_ind,
              maxLength: 13,
            ),
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: claveElectorController,
              label: 'Clave de Elector',
              icon: Icons.switch_account_rounded,
              maxLength: 18,
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
              ),
              if (_nombreBanco == "Santander") ...[
                const SizedBox(height: verticalSpacing),
                _buildTextField(
                  controller: _claveInterbancariaController,
                  label: 'Clave Interbancaria',
                  icon: Icons.security,
                  keyboardType: TextInputType.number,
                  maxLength: 18,
                ),
              ],
              const SizedBox(height: verticalSpacing),
              _buildTextField(
                controller: _numCuentaController,
                label: 'Número de Cuenta',
                icon: Icons.account_balance_wallet,
                keyboardType: TextInputType.number,
                maxLength: 11,
              ),
              const SizedBox(height: verticalSpacing),
              _buildTextField(
                controller: _numTarjetaController,
                label: 'Número de Tarjeta',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                maxLength: 16,
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
              height: MediaQuery.of(context).size.height * 0.91,
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
              height: MediaQuery.of(context).size.height * 0.91,
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
    // ... Implementación idéntica ...
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
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
    // ... Implementación idéntica ...
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
    // ... Implementación idéntica ...
    switch (_currentIndex) {
      case 0:
        return _personalFormKey.currentState?.validate() ?? false;
      case 1:
        return _noCuentaBancaria
            ? true
            : (_cuentaBancariaFormKey.currentState?.validate() ?? false);
      default:
        return true;
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
            style: TextStyle(color: colors.textPrimary),
            // ¡Importante! Ocultamos el contador por defecto para evitar duplicados y espacios raros.
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: colors.textSecondary),
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
    // ... Implementación idéntica ...
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
        hint: Text(hint, style: TextStyle(color: colors.textSecondary)),
        items:
            items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(color: colors.textPrimary),
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
    // ... Implementación idéntica ...
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
            vertical: 14,
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

  //endregion
}
