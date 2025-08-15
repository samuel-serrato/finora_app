import 'dart:async';
import 'dart:convert';
import 'package:finora_app/helpers/responsive_helpers.dart';
import 'package:finora_app/ip.dart';
import 'package:finora_app/models/grupos.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/credito_service.dart';
import 'package:finora_app/utils/redondeo.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/clientes.dart';
import '../../utils/app_logger.dart';


// TODO: Mueve esta URL a tu archivo de configuración central (ej. ip.dart)

//region Modelos de Datos (Copiados de tu versión Desktop)
class TasaInteres {
  final int idtipointeres;
  final double mensual;
  final String fCreacion;

  TasaInteres({
    required this.idtipointeres,
    required this.mensual,
    required this.fCreacion,
  });

  factory TasaInteres.fromJson(Map<String, dynamic> json) {
    return TasaInteres(
      idtipointeres: json['idtipointeres'],
      mensual: (json['mensual'] as num).toDouble(),
      fCreacion: json['fCreacion'],
    );
  }
}

class Duracion {
  final int idduracion;
  final int plazo;
  final String frecuenciaPago;
  final DateTime fCreacion;

  Duracion({
    required this.idduracion,
    required this.plazo,
    required this.frecuenciaPago,
    required this.fCreacion,
  });

  factory Duracion.fromJson(Map<String, dynamic> json) {
    return Duracion(
      idduracion: json['idduracion'],
      plazo: json['plazo'],
      frecuenciaPago: json['frecuenciaPago'],
      fCreacion: DateTime.parse(json['fCreacion']),
    );
  }
}

/* class Grupo {
  final String idgrupos;
  final String nombreGrupo;
  final String estado;
  final List<Cliente> clientes;

  Grupo({
    required this.idgrupos,
    required this.nombreGrupo,
    required this.estado,
    required this.clientes,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) {
    return Grupo(
      idgrupos: json['idgrupos'],
      nombreGrupo: json['nombreGrupo'],
      estado: json['estado'],
      clientes:
          (json['clientes'] as List)
              .map((clienteJson) => Cliente.fromJson(clienteJson))
              .toList(),
    );
  }
}

class Cliente {
  final String iddetallegrupos;
  final String idclientes;
  final String nombres;

  Cliente({
    required this.iddetallegrupos,
    required this.idclientes,
    required this.nombres,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      iddetallegrupos: json['iddetallegrupos'],
      idclientes: json['idclientes'],
      nombres: json['nombres'],
    );
  }
} */
//endregion

class nCreditoForm extends StatefulWidget {
  final VoidCallback? onCreditoAgregado;

  const nCreditoForm({super.key, this.onCreditoAgregado});

  @override
  State<nCreditoForm> createState() => _nCreditoFormState();
}

class _nCreditoFormState extends State<nCreditoForm>
    with SingleTickerProviderStateMixin {
  //region Controladores y Variables de Estado
  late TabController _tabController;
  int _currentIndex = 0;

  final GlobalKey<FormState> _datosGeneralesFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _integrantesFormKey = GlobalKey<FormState>();

  final montoController = TextEditingController();
  final List<TextEditingController> _controladoresIntegrantes = [];

  // Variables de estado para los dropdowns y la fecha
  String? selectedGrupoId;
  String? garantia;
  String? frecuenciaPago = "Semanal"; // Valor predeterminado
  String? diaPago;
  DateTime fechaInicio = DateTime.now();

  TasaInteres? _tasaSeleccionada;
  Duracion? _duracionSeleccionada;

  // Listas para almacenar datos de la API
  List<Grupo> _listaGrupos = [];
  List<TasaInteres> _listaTasas = [];
  List<Duracion> _listaDuraciones = [];

  // Datos de integrantes
  List<ClienteResumenGrupo> integrantes = [];
  Map<String, double> montosIndividuales = {};
  Map<String, double> _descuentosRenovacion = {};

  // Banderas de estado (Carga, Error, Guardado)
  bool _isLoading = true;
  String? _errorConfig;
  bool _cargandoDescuentos = false;
  bool _isSaving = false;

  // <<< --- AÑADE LA INSTANCIA DEL SERVICIO --- >>>
  final CreditoService _creditoService = CreditoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentIndex = _tabController.index);
    });
    diaPago = _diaDeLaSemana(fechaInicio);
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _tabController.dispose();
    montoController.dispose();
    for (var controller in _controladoresIntegrantes) {
      controller.dispose();
    }
    super.dispose();
  }

  //region Lógica de Negocio y API (Adaptado de tu versión Desktop)

  // <<< CAMBIO 1: La función principal de carga ahora es mucho más limpia. >>>
  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
      _errorConfig = null;
    });

    try {
      // Usamos Future.wait para ejecutar todas las llamadas al servicio en paralelo.
      final results = await Future.wait([
        _creditoService.getGruposDisponibles(),
        _creditoService.getTasasDeInteres(),
        _creditoService.getDuraciones(),
      ]);

      // Extraemos las respuestas. Future.wait mantiene el orden.
      final ApiResponse<List<Grupo>> gruposResponse =
          results[0] as ApiResponse<List<Grupo>>;
      final ApiResponse<List<TasaInteres>> tasasResponse =
          results[1] as ApiResponse<List<TasaInteres>>;
      final ApiResponse<List<Duracion>> duracionesResponse =
          results[2] as ApiResponse<List<Duracion>>;

      // Verificamos que todas las peticiones esenciales fueran exitosas.
      if (gruposResponse.success &&
          tasasResponse.success &&
          duracionesResponse.success) {
        // Si todo está bien, actualizamos el estado una sola vez.
        if (mounted) {
          setState(() {
            _listaGrupos = gruposResponse.data!;
            _listaTasas = tasasResponse.data!;
            _listaDuraciones = duracionesResponse.data!;
          });
        }
      } else {
        // Si algo falló, el ApiService ya mostró el error.
        // Aquí solo registramos el error para mostrar la vista de "Reintentar".
        throw Exception("Una o más peticiones de configuración fallaron.");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorConfig = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // <<< CAMBIO 2: La carga de descuentos también se mueve al servicio >>>
  Future<void> _cargarDescuentosRenovacion(String idgrupo) async {
    if (idgrupo.isEmpty || !mounted) return;

    setState(() => _cargandoDescuentos = true);

    // Llamamos al método del servicio
    final response = await _creditoService.getDescuentosRenovacion(idgrupo);

    if (mounted) {
      // Actualizamos el estado con la data de la respuesta si fue exitosa
      if (response.success) {
        setState(() {
          _descuentosRenovacion = response.data ?? {};
        });
      }
      // No manejamos el error aquí porque el servicio está configurado para no mostrar diálogo.
      // Simplemente no se mostrarán descuentos si falla.
      setState(() => _cargandoDescuentos = false);
    }
  }

  Future<void> _guardarCredito() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // 1. Generar los datos sigue siendo responsabilidad del widget.
      final datosParaServidor = _generarDatosParaServidor(context);
      if (datosParaServidor.isEmpty) {
        // Esta validación se mantiene aquí, ya que ocurre antes de llamar a la API.
        _showErrorDialog(
          "Error Interno",
          "No se pudieron generar los datos para enviar el crédito. Revisa que todos los campos estén completos.",
        );
        // Importante: retorna para no continuar si los datos son inválidos.
        return;
      }

      // 2. Llamar al nuevo servicio en lugar de http.post
      // La lógica de la URL, headers, token y body ahora está en CreditoService y ApiService.
      final ApiResponse<Map<String, dynamic>> response = await _creditoService
          .crearCredito(datosParaServidor);

      // 3. Manejar la respuesta del servicio
      if (mounted && response.success) {
        // Éxito: La UI reacciona como antes.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Crédito guardado exitosamente',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onCreditoAgregado?.call();
        Navigator.of(context).pop();
      }
      // ¡No necesitas un 'else'!
      // Si response.success es false, el ApiService ya se encargó
      // de mostrar el diálogo de error correspondiente.
    } catch (e) {
      // Este bloque catch ahora solo atrapará errores de programación
      // dentro de este método, no errores de red (que son manejados por ApiService).
      // Es bueno mantenerlo por seguridad.
      if (mounted) {
        _showErrorDialog(
          "Error Inesperado en la App",
          "Ocurrió un error localmente: ${e.toString()}",
        );
      }
    } finally {
      // 4. Siempre desactivar el overlay de carga, sin importar el resultado.
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  //endregion

  //region Getters y Helpers de UI/Lógica
  List<Duracion> get _duracionesFiltradas {
    if (frecuenciaPago == null) return [];
    return _listaDuraciones
        .where((d) => d.frecuenciaPago == frecuenciaPago)
        .toList();
  }

  String _diaDeLaSemana(DateTime fecha) {
    const dias = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo",
    ];
    return dias[fecha.weekday - 1];
  }

  double _obtenerMontoReal(String formattedValue) {
    if (formattedValue.isEmpty) return 0.0;
    String sanitized = formattedValue.replaceAll(',', '');
    return double.tryParse(sanitized) ?? 0.0;
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  String _formatearNumero(double numero) {
    final formatter = NumberFormat("#,##0.00", "es_MX");
    return formatter.format(numero);
  }

  double _getGarantiaPorcentaje() {
    if (garantia == null || garantia == "Sin garantía") return 0.0;
    final valorNumerico =
        double.tryParse(garantia!.replaceAll('%', '').trim()) ?? 0.0;
    return valorNumerico / 100.0;
  }

  //endregion

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    // 1. Reemplazamos Scaffold por Card.
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
              : _errorConfig != null
              ? _buildErrorView() // Tu vista de error se mantiene
              : Stack(
                // Mantenemos el Stack para el overlay de "guardando"
                children: [
                  Column(
                    children: [
                      // 2. Añadimos el nuevo encabezado del diálogo.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Agregar Crédito', // Título que reemplaza al AppBar
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. Tus widgets originales (TabBar, TabBarView) se integran aquí.
                      Container(
                        margin: const EdgeInsets.all(16),
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
                          tabs: const [
                            Tab(text: 'Generales'),
                            Tab(text: 'Integrantes'),
                            Tab(text: 'Resumen'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _paginaDatosGenerales(),
                            _paginaIntegrantes(),
                            _paginaResumen(),
                          ],
                        ),
                      ),
                      _buildNavigationButtons(), // Tus botones de navegación al final
                    ],
                  ),

                  // El overlay de "guardando" se queda en el Stack para cubrir todo el diálogo.
                  if (_isSaving)
                    Container(
                      // Le agregamos bordes redondeados para que coincida con la Card.
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20.0),
                        ),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
    );
  }

  //region Widgets de Páginas (Tabs)

  // lib/src/widgets/n_credito_form.dart (o donde esté tu clase nCreditoForm)

// ... (resto del código de tu clase _nCreditoFormState)

  Widget _paginaDatosGenerales() {
    const double verticalSpacing = 16.0;
    // <<< CAMBIO 1: Usamos tu helper para detectar el tipo de pantalla >>>
    final bool esDesktop = context.isDesktop;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Form(
        key: _datosGeneralesFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Información del Crédito'),
            
            // <<< CAMBIO 2: Lógica condicional para el layout >>>
            if (esDesktop) ...[
              // --- LAYOUT PARA DESKTOP (CON ROWS) ---

              // Fila 1: Grupo y Monto
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildModelDropdown<Grupo>(
                      value: selectedGrupoId == null
                          ? null
                          : _listaGrupos.firstWhere((g) => g.idgrupos == selectedGrupoId),
                      hint: 'Seleccionar Grupo',
                      items: _listaGrupos,
                      itemBuilder: (grupo) => Text(grupo.nombreGrupo),
                      onChanged: (grupo) {
                        if (grupo == null) return;
                        setState(() {
                          selectedGrupoId = grupo.idgrupos;
                          integrantes = grupo.clientes;
                          montosIndividuales.clear();
                          _controladoresIntegrantes.clear();
                          for (var integrante in integrantes) {
                            montosIndividuales[integrante.idclientes] = 0.0;
                            _controladoresIntegrantes.add(TextEditingController());
                          }
                          _cargarDescuentosRenovacion(grupo.idgrupos);
                        });
                      },
                      validator: (g) => g == null ? 'Seleccione un grupo' : null,
                    ),
                  ),
                  const SizedBox(width: verticalSpacing),
                  Expanded(
                    child: _buildTextField(
                      controller: montoController,
                      label: 'Monto Autorizado',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\.]'))],
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: verticalSpacing),

              // Fila 2: Tasa y Garantía
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildModelDropdown<TasaInteres>(
                      value: _tasaSeleccionada,
                      hint: 'Tasa de Interés',
                      items: _listaTasas,
                      itemBuilder: (tasa) => Text('${tasa.mensual}% Mensual'),
                      onChanged: (tasa) => setState(() => _tasaSeleccionada = tasa),
                      validator: (tasa) => tasa == null ? 'Seleccione una tasa' : null,
                    ),
                  ),
                  const SizedBox(width: verticalSpacing),
                  Expanded(
                    child: _buildDropdown(
                      value: garantia,
                      hint: 'Garantía',
                      items: ["Sin garantía", "5%", "10%"],
                      onChanged: (value) => setState(() => garantia = value),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: verticalSpacing * 2),
              _sectionTitle('Configuración de Pagos'),

              // Fila 3: Frecuencia, Plazo y Fecha
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDropdown(
                      value: frecuenciaPago,
                      hint: 'Frecuencia de Pago',
                      items: ["Semanal", "Quincenal"],
                      onChanged: (value) {
                        setState(() {
                          frecuenciaPago = value;
                          _duracionSeleccionada = null;
                        });
                      },
                      validator: (v) => v == null ? 'Seleccione la frecuencia' : null,
                    ),
                  ),
                  const SizedBox(width: verticalSpacing),
                  Expanded(
                    child: _buildModelDropdown<Duracion>(
                      value: _duracionSeleccionada,
                      hint: 'Plazo',
                      items: _duracionesFiltradas,
                      itemBuilder: (d) => Text('${d.plazo} pagos'),
                      onChanged: (duracion) => setState(() => _duracionSeleccionada = duracion),
                      validator: (d) => d == null ? 'Seleccione un plazo' : null,
                    ),
                  ),
                   const SizedBox(width: verticalSpacing),
                  Expanded(child: _buildFechaInicioField()),
                ],
              ),

            ] else ...[
              // --- LAYOUT ORIGINAL PARA MÓVIL/TABLET (UNA COLUMNA) ---
              
              _buildModelDropdown<Grupo>(
                value: selectedGrupoId == null
                    ? null
                    : _listaGrupos.firstWhere((g) => g.idgrupos == selectedGrupoId),
                hint: 'Seleccionar Grupo',
                items: _listaGrupos,
                itemBuilder: (grupo) => Text(grupo.nombreGrupo),
                onChanged: (grupo) {
                  if (grupo == null) return;
                  setState(() {
                    selectedGrupoId = grupo.idgrupos;
                    integrantes = grupo.clientes;
                    montosIndividuales.clear();
                    _controladoresIntegrantes.clear();
                    for (var integrante in integrantes) {
                      montosIndividuales[integrante.idclientes] = 0.0;
                      _controladoresIntegrantes.add(TextEditingController());
                    }
                    _cargarDescuentosRenovacion(grupo.idgrupos);
                  });
                },
                validator: (g) => g == null ? 'Seleccione un grupo' : null,
              ),
              const SizedBox(height: verticalSpacing),
              _buildTextField(
                controller: montoController,
                label: 'Monto Autorizado',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\.]'))],
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: verticalSpacing),
              _buildModelDropdown<TasaInteres>(
                value: _tasaSeleccionada,
                hint: 'Tasa de Interés',
                items: _listaTasas,
                itemBuilder: (tasa) => Text('${tasa.mensual}% Mensual'),
                onChanged: (tasa) => setState(() => _tasaSeleccionada = tasa),
                validator: (tasa) => tasa == null ? 'Seleccione una tasa' : null,
              ),
              const SizedBox(height: verticalSpacing),
              _buildDropdown(
                value: garantia,
                hint: 'Garantía',
                items: ["Sin garantía", "5%", "10%"],
                onChanged: (value) => setState(() => garantia = value),
                validator: (v) => v == null ? 'Requerido' : null,
              ),
              const SizedBox(height: verticalSpacing * 2),
              _sectionTitle('Configuración de Pagos'),
              _buildDropdown(
                value: frecuenciaPago,
                hint: 'Frecuencia de Pago',
                items: ["Semanal", "Quincenal"],
                onChanged: (value) {
                  setState(() {
                    frecuenciaPago = value;
                    _duracionSeleccionada = null;
                  });
                },
                validator: (v) => v == null ? 'Seleccione la frecuencia' : null,
              ),
              const SizedBox(height: verticalSpacing),
              _buildModelDropdown<Duracion>(
                value: _duracionSeleccionada,
                hint: 'Plazo',
                items: _duracionesFiltradas,
                itemBuilder: (d) => Text('${d.plazo} pagos'),
                onChanged: (duracion) => setState(() => _duracionSeleccionada = duracion),
                validator: (d) => d == null ? 'Seleccione un plazo' : null,
              ),
              const SizedBox(height: verticalSpacing),
              _buildFechaInicioField(),
            ],

            // <<< CAMBIO 3: Elementos comunes al final >>>
            const SizedBox(height: verticalSpacing),
            Text(
              'Día de pago sugerido: $diaPago',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
// ... (resto del código de tu clase _nCreditoFormState)

  Widget _paginaIntegrantes() {
    if (selectedGrupoId == null) {
      return const Center(
        child: Text("Seleccione un grupo en la pestaña anterior."),
      );
    }
    if (_cargandoDescuentos) {
      return const Center(child: CircularProgressIndicator());
    }

   final themeProvider = Provider.of<ThemeProvider>(context);
final colors = themeProvider.colors;

double sumaTotal = montosIndividuales.values.fold(
  0.0,
  (sum, amount) => sum + amount,
);

// --- INICIO DE LA MODIFICACIÓN ---

// 1. Obtén un conjunto de los IDs de los integrantes actuales para una búsqueda rápida.
final idsIntegrantesActuales = integrantes.map((c) => c.idclientes).toSet();

// 2. Calcula el total de descuentos SOLO para los integrantes actuales.
double descuentoTotal = _descuentosRenovacion.entries
    .where((entry) => idsIntegrantesActuales.contains(entry.key)) // Filtra por ID
    .map((entry) => entry.value) // Obtiene solo los montos
    .fold(0.0, (sum, discount) => sum + discount); // Suma los montos filtrados

// --- FIN DE LA MODIFICACIÓN ---

final double totalGarantia = sumaTotal * _getGarantiaPorcentaje();

    return Form(
      key: _integrantesFormKey,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: integrantes.length,
              itemBuilder: (context, index) {
                final cliente = integrantes[index];
                final double? descuento =
                    _descuentosRenovacion[cliente.idclientes];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: colors.backgroundCard,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombres,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _controladoresIntegrantes[index],
                          label: 'Monto Solicitado',
                          icon: Icons.monetization_on,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator:
                              (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Requerido'
                                      : null,
                          onChanged: (value) {
                            double parsedValue = _obtenerMontoReal(value);
                            setState(() {
                              montosIndividuales[cliente.idclientes] =
                                  parsedValue;
                            });
                          },
                        ),
                        if (descuento != null && descuento > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Chip(
                              avatar: Icon(
                                Icons.arrow_downward,
                                color: Colors.green.shade800,
                                size: 16,
                              ),
                              label: Text(
                                'Descuento: \$${_formatearNumero(descuento)}',
                                style: TextStyle(color: Colors.green.shade800),
                              ),
                              backgroundColor: Colors.green.withOpacity(0.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Contenedor de totales
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              children: [
                _infoRow(
                  'Suma Solicitado:',
                  '\$${_formatearNumero(sumaTotal)}',
                ),
                if (descuentoTotal > 0)
                  _infoRow(
                    'Total Descuentos:',
                    '-\$${_formatearNumero(descuentoTotal)}',
                    valueColor: Colors.green,
                  ),
                if (totalGarantia > 0)
                  _infoRow(
                    'Total Garantía:',
                    '-\$${_formatearNumero(totalGarantia)}',
                    valueColor: Colors.orange,
                  ),
                const Divider(height: 20),
                _infoRow(
                  'Monto Neto a Financiar:',
                  '\$${_formatearNumero(sumaTotal - descuentoTotal - totalGarantia)}',
                  isBold: true,
                  valueColor: colors.brandPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paginaResumen() {
    // --- Validación inicial (sin cambios) ---
    if (selectedGrupoId == null ||
        _tasaSeleccionada == null ||
        _duracionSeleccionada == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Completa los Datos Generales para ver el resumen.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // --- Bloque de Cálculos (sin cambios) ---
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    final double monto = _obtenerMontoReal(montoController.text);
    final int plazo = _duracionSeleccionada!.plazo;
    final double tasaMensual = _tasaSeleccionada!.mensual;
    final double tasaMensualDecimal = tasaMensual / 100.0;
    final String frecuencia = frecuenciaPago ?? "Semanal";

    double interesPagoPeriodico = 0;
    double capitalPagoPeriodico = 0;
    double interesPorcentajePeriodico = 0;
    double interesGlobalPorcentaje = 0;

    if (frecuencia == "Semanal") {
      interesPorcentajePeriodico = tasaMensual / 4;
      interesGlobalPorcentaje = interesPorcentajePeriodico * plazo;
      interesPagoPeriodico = monto * (interesPorcentajePeriodico / 100);
      capitalPagoPeriodico = (plazo > 0) ? monto / plazo : 0;
    } else {
      // Quincenal
      interesPorcentajePeriodico = tasaMensual / 2;
      interesGlobalPorcentaje = interesPorcentajePeriodico * plazo;
      interesPagoPeriodico = monto * (interesPorcentajePeriodico / 100);
      capitalPagoPeriodico = (plazo > 0) ? monto / plazo : 0;
    }

    final double pagoTotalPeriodicoOriginal =
        capitalPagoPeriodico + interesPagoPeriodico;
    final double pagoTotalPeriodicoRedondeado =
        redondearDecimales(pagoTotalPeriodicoOriginal, context).toDouble();

    final double totalARecuperar = pagoTotalPeriodicoRedondeado * plazo;
    final double interesTotal = totalARecuperar - monto;

    final double montoGarantia = monto * _getGarantiaPorcentaje();

// --- APLICA LA MISMA CORRECCIÓN AQUÍ ---
final idsIntegrantesActuales = integrantes.map((c) => c.idclientes).toSet();
final double totalDescuentos = _descuentosRenovacion.entries
    .where((entry) => idsIntegrantesActuales.contains(entry.key))
    .map((entry) => entry.value)
    .fold(0.0, (sum, discount) => sum + discount);
// --- FIN DE LA CORRECCIÓN ---

final double montoDesembolsado = monto - montoGarantia - totalDescuentos;

    // --- Construcción de la UI ---
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // --- TARJETA 1: DATOS GENERALES (sin cambios) ---
          _buildResumenExpandableCard(
            title: 'Resumen General',
            icon: Icons.account_balance_wallet,
            isInitiallyExpanded: true,
            children: [
              _infoRow('Monto Autorizado:', '\$${_formatearNumero(monto)}'),
              const SizedBox(height: 10),
              _infoRowWithTooltip(
                context: context,
                label: 'Monto a Desembolsar:',
                value: '\$${_formatearNumero(montoDesembolsado)}',
                isBold: true,
                valueColor: colors.brandPrimary,
                tooltipContent: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Desglose del Desembolso",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    _buildTooltipContentRow(
                      'Monto Autorizado',
                      '\$${_formatearNumero(monto)}',
                    ),
                    if (montoGarantia > 0)
                      _buildTooltipContentRow(
                        '(-) Garantía',
                        '-\$${_formatearNumero(montoGarantia)}',
                      ),
                    if (totalDescuentos > 0)
                      _buildTooltipContentRow(
                        '(-) Descuento Renov.',
                        '-\$${_formatearNumero(totalDescuentos)}',
                      ),
                    const Divider(),
                    _buildTooltipContentRow(
                      '(=) Total a Recibir',
                      '\$${_formatearNumero(montoDesembolsado)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              _infoRow('Garantía:', garantia ?? 'Sin garantía'),
              _infoRow('Frecuencia de Pago:', frecuencia),
              _infoRow('Plazo:', '$plazo pagos'),
              _infoRow('Día de Pago:', diaPago ?? 'N/A'),
              const SizedBox(height: 10),
              _infoRow(
                'Tasa de Interés Mensual:',
                '${tasaMensual.toStringAsFixed(2)}%',
              ),
              _infoRow(
                'Interés $frecuencia (%):',
                '${interesPorcentajePeriodico.toStringAsFixed(2)}%',
              ),
              _infoRow(
                'Interés Global:',
                '${interesGlobalPorcentaje.toStringAsFixed(2)}%',
              ),
              const SizedBox(height: 10),
              _infoRow(
                'Capital $frecuencia:',
                '\$${_formatearNumero(capitalPagoPeriodico)}',
              ),
              _infoRow(
                'Interés $frecuencia (\$):',
                '\$${_formatearNumero(interesPagoPeriodico)}',
              ),
              const Divider(height: 20),
              _infoRowWithTooltip(
                context: context,
                label: 'Pago $frecuencia:',
                value: '\$${_formatearNumero(pagoTotalPeriodicoRedondeado)}',
                isBold: true,
                tooltipContent: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Detalle del Redondeo",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    _buildTooltipContentRow(
                      'Valor Original',
                      '\$${_formatearNumero(pagoTotalPeriodicoOriginal)}',
                    ),
                    _buildTooltipContentRow(
                      'Valor Redondeado',
                      '\$${_formatearNumero(pagoTotalPeriodicoRedondeado)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _infoRow(
                'Interés Total a Pagar:',
                '\$${_formatearNumero(interesTotal)}',
              ),
              _infoRow(
                'Total a Recuperar:',
                '\$${_formatearNumero(totalARecuperar)}',
                isBold: true,
              ),
            ],
          ),

          // --- TARJETA 2: INTEGRANTES (CON DATOS ADICIONALES) ---
          _buildResumenExpandableCard(
            title: 'Integrantes y Montos',
            icon: Icons.groups,
            children:
                integrantes.map((integrante) {
                  // --- Cálculos individuales ---
                  final montoIndividual =
                      montosIndividuales[integrante.idclientes] ?? 0.0;
                  final descuentoIndividual =
                      _descuentosRenovacion[integrante.idclientes] ?? 0.0;
                  final proporcion =
                      (monto > 0) ? montoIndividual / monto : 0.0;
                  final garantiaIndividual = montoGarantia * proporcion;
                  final montoDesembolsadoIndividual =
                      montoIndividual -
                      descuentoIndividual -
                      garantiaIndividual;
                  final tieneDeducciones =
                      descuentoIndividual > 0 || garantiaIndividual > 0;

                  final capitalPeriodicoIndividual =
                      (plazo > 0) ? (montoIndividual / plazo) : 0.0;
                  final interesPeriodicoIndividual =
                      proporcion * interesPagoPeriodico;
                  final pagoPeriodicoIndividual =
                      capitalPeriodicoIndividual + interesPeriodicoIndividual;

                  // --- NUEVOS CÁLCULOS PARA TOTALES INDIVIDUALES ---
                  final totalCapitalIndividual = montoIndividual;
                  final totalInteresIndividual =
                      interesPeriodicoIndividual * plazo;
                  final pagoTotalIndividual =
                      totalCapitalIndividual + totalInteresIndividual;

                  return Card(
                    elevation: 0,
                    color:
                        themeProvider.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[100],
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            integrante.nombres,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Divider(),
                          _infoRow(
                            'Monto Solicitado:',
                            '\$${_formatearNumero(montoIndividual)}',
                          ),
                          _infoRowWithTooltip(
                            context: context,
                            label: 'Desembolsado:',
                            value:
                                '\$${_formatearNumero(montoDesembolsadoIndividual)}',
                            valueColor:
                                tieneDeducciones ? Colors.green.shade600 : null,
                            tooltipContent: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Desglose Individual",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Divider(),
                                _buildTooltipContentRow(
                                  'Monto Solicitado',
                                  '\$${_formatearNumero(montoIndividual)}',
                                ),
                                if (garantiaIndividual > 0)
                                  _buildTooltipContentRow(
                                    '(-) Garantía',
                                    '-\$${_formatearNumero(garantiaIndividual)}',
                                  ),
                                if (descuentoIndividual > 0)
                                  _buildTooltipContentRow(
                                    '(-) Descuento Renov.',
                                    '-\$${_formatearNumero(descuentoIndividual)}',
                                  ),
                                const Divider(),
                                _buildTooltipContentRow(
                                  '(=) Total a Recibir',
                                  '\$${_formatearNumero(montoDesembolsadoIndividual)}',
                                  isTotal: true,
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 15,
                            thickness: 0.5,
                            indent: 20,
                            endIndent: 20,
                          ),

                          // --- DATOS POR PERIODO ---
                          _infoRow(
                            'Pago $frecuencia:',
                            '\$${_formatearNumero(pagoPeriodicoIndividual)}',
                          ),
                          _infoRow(
                            'Capital $frecuencia:',
                            '\$${_formatearNumero(capitalPeriodicoIndividual)}',
                          ),
                          _infoRow(
                            'Interés $frecuencia (\$):',
                            '\$${_formatearNumero(interesPeriodicoIndividual)}',
                          ),
                          const Divider(
                            height: 15,
                            thickness: 0.5,
                            indent: 20,
                            endIndent: 20,
                          ),

                          // --- NUEVOS DATOS: TOTALES FINALES DEL MIEMBRO ---
                          _infoRow(
                            'Total Capital:',
                            '\$${_formatearNumero(totalCapitalIndividual)}',
                          ),
                          _infoRow(
                            'Total Intereses:',
                            '\$${_formatearNumero(totalInteresIndividual)}',
                          ),
                          _infoRow(
                            'Pago Total (Final):',
                            '\$${_formatearNumero(pagoTotalIndividual)}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),

          // --- TARJETA 3: CALENDARIO DE PAGOS (sin cambios) ---
          _buildResumenExpandableCard(
            title: 'Calendario de Pagos',
            icon: Icons.calendar_today,
            children: [
              ListTile(
                dense: true,
                leading: const CircleAvatar(
                  child: Text('0', style: TextStyle(fontSize: 14)),
                  maxRadius: 16,
                ),
                title: Text(_formatearFecha(fechaInicio)),
                subtitle: const Text('Disposición del crédito'),
                trailing: Text(
                  '\$${_formatearNumero(totalARecuperar)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),

              // --- INICIO DE LA MODIFICACIÓN ---
              ...() {
                // Usamos una función anónima para poder tener un if/else
                List<DateTime> fechasDePagoCalculadas = [];
                if (frecuencia == "Quincenal") {
                  fechasDePagoCalculadas =
                      calcularFechasDePago(
                        fechaInicio,
                        plazo,
                      ).map((f) => DateTime.parse(f)).toList();
                }

                return List.generate(plazo, (index) {
                  final DateTime fechaPago;
                  if (frecuencia == "Semanal") {
                    fechaPago = fechaInicio.add(
                      Duration(days: (index + 1) * 7),
                    );
                  } else {
                    // Quincenal
                    fechaPago = fechasDePagoCalculadas[index];
                  }
                  final restante =
                      totalARecuperar -
                      (pagoTotalPeriodicoRedondeado * (index + 1));
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(fontSize: 14),
                      ),
                      maxRadius: 16,
                    ),
                    title: Text(_formatearFecha(fechaPago)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Capital: \$${_formatearNumero(capitalPagoPeriodico)}',
                        ),
                        Text(
                          'Interés: \$${_formatearNumero(interesPagoPeriodico)}',
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_formatearNumero(pagoTotalPeriodicoRedondeado)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Resta: \$${_formatearNumero(restante)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                });
              }(),
              // --- FIN DE LA MODIFICACIÓN --
            ],
          ),
        ],
      ),
    );
  }

  //endregion

  //region Widgets de UI Auxiliares
  Widget _buildNavigationButtons() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      padding: const EdgeInsets.all(
        16.0,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
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
              backgroundColor: colors.brandPrimary,
              foregroundColor: colors.whiteWhite,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(_currentIndex == 2 ? 'Guardar Crédito' : 'Siguiente'),
          ),
        ],
      ),
    );
  }

  // NUEVO HELPER para filas con Tooltip
  Widget _infoRowWithTooltip({
    required BuildContext context,
    required String label,
    required String value,
    required Widget tooltipContent,
    bool isBold = false,
    Color? valueColor,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: valueColor ?? colors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                richMessage: WidgetSpan(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.backgroundCard,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: tooltipContent,
                  ),
                ),
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 5),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colors.brandPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NUEVO HELPER para el contenido de los Tooltips
  Widget _buildTooltipContentRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextOrSave() async {
    FocusScope.of(context).unfocus();

    if (!_validarFormularioActual()) {
      _showErrorDialog(
        "Campos Incompletos",
        "Por favor, complete todos los campos requeridos en esta sección.",
      );
      return;
    }

    if (_currentIndex == 1) {
      // Pestaña de integrantes
      double montoTotal = _obtenerMontoReal(montoController.text);
      double sumaIndividual = montosIndividuales.values.fold(
        0.0,
        (prev, e) => prev + e,
      );
      if ((sumaIndividual - montoTotal).abs() > 0.01) {
        _showErrorDialog(
          "Montos no coinciden",
          "La suma de los montos individuales (\$${_formatearNumero(sumaIndividual)}) no coincide con el monto total autorizado (\$${_formatearNumero(montoTotal)}).",
        );
        return;
      }
    }

    if (_currentIndex < 2) {
      _tabController.animateTo(_currentIndex + 1);
    } else {
      _guardarCredito();
    }
  }

  bool _validarFormularioActual() {
    switch (_currentIndex) {
      case 0:
        return _datosGeneralesFormKey.currentState?.validate() ?? false;
      case 1:
        return _integrantesFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  Widget _buildResumenCard({
    required String title,
    required List<Widget> children,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: colors.backgroundCard,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colors.brandPrimary,
              ),
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? colors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar la configuración',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No se pudieron obtener los datos necesarios. Por favor, verifica tu conexión e inténtalo de nuevo.\n\nDetalle: $_errorConfig',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarDatosIniciales,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // Copia este helper a tu archivo
  Widget _buildResumenExpandableCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isInitiallyExpanded = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: colors.backgroundCard,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: isInitiallyExpanded,
        leading: Icon(icon, color: colors.brandPrimary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        backgroundColor: colors.backgroundCard,
        collapsedBackgroundColor: colors.backgroundCard,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ).copyWith(bottom: 16.0),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
          prefixIcon: Icon(icon, color: colors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.divider),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: validator,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(
        hint,
        style: TextStyle(color: colors.textSecondary, fontSize: 14),
      ),
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
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider),
        ),
        filled: true,
        fillColor: colors.backgroundCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      dropdownColor: colors.backgroundCard,
    );
  }

  Widget _buildModelDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint, style: TextStyle(color: colors.textSecondary)),
      items:
          items
              .map(
                (item) =>
                    DropdownMenuItem<T>(value: item, child: itemBuilder(item)),
              )
              .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider),
        ),
        filled: true,
        fillColor: colors.backgroundCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      dropdownColor: colors.backgroundCard,
      style: TextStyle(color: colors.textPrimary),
    );
  }

  Widget _buildFechaInicioField() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: _formatearFecha(fechaInicio)),
      decoration: InputDecoration(
        labelText: 'Fecha de Inicio',
        labelStyle: TextStyle(color: colors.textSecondary),
        prefixIcon: Icon(Icons.calendar_today, color: colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider),
        ),
        filled: true,
        fillColor: colors.backgroundCard,
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: fechaInicio,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          locale: const Locale('es', 'ES'),
        );
        if (pickedDate != null) {
          setState(() {
            fechaInicio = pickedDate;
            diaPago = _diaDeLaSemana(fechaInicio);
          });
        }
      },
    );
  }

  Widget _sectionTitle(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
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
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }

  //endregion

  //region Generador de Payload para API
  Map<String, dynamic> _generarDatosParaServidor(BuildContext context) {
    // 1. --- VALIDACIÓN INICIAL ---
    // Si faltan datos esenciales, se devuelve un mapa vacío para detener el proceso.
    if (selectedGrupoId == null ||
        _tasaSeleccionada == null ||
        _duracionSeleccionada == null) {
      AppLogger.log("Error: Faltan datos de configuración para generar el payload.");
      return {};
    }

    // 2. --- EXTRACCIÓN DE DATOS BASE ---
    // Obtenemos los objetos y valores seleccionados por el usuario.
    final grupo = _listaGrupos.firstWhere((g) => g.idgrupos == selectedGrupoId);
    final tasa = _tasaSeleccionada!;
    final duracion = _duracionSeleccionada!;
    final double montoTotalCredito = _obtenerMontoReal(montoController.text);
    final int numeroDePagos = duracion.plazo;
    final double tasaMensualDecimal = tasa.mensual / 100.0;

    // 3. --- CÁLCULO DE VALORES PRECISOS (SIN REDONDEAR) ---
    // Calculamos todos los componentes del crédito con la máxima precisión posible.
    double interesPorcentajePorPeriodo;
    if (duracion.frecuenciaPago == "Semanal") {
      interesPorcentajePorPeriodo = tasa.mensual / 4;
    } else {
      // Quincenal
      interesPorcentajePorPeriodo = tasa.mensual / 2;
    }

    final double interesGlobalCalculado =
        interesPorcentajePorPeriodo * numeroDePagos;
    final double capitalPorPeriodo = montoTotalCredito / numeroDePagos;
    final double interesPorPeriodo =
        montoTotalCredito * (interesPorcentajePorPeriodo / 100.0);
    final double pagoCuotaOriginal = capitalPorPeriodo + interesPorPeriodo;

    // 4. --- APLICACIÓN DEL REDONDEO (LA PARTE CLAVE) ---
    // Aquí usamos tu función de redondeo para obtener los valores que se enviarán.
    final double pagoCuotaRedondeado =
        redondearDecimales(pagoCuotaOriginal, context).toDouble();

    // 5. --- RE-CÁLCULO DE TOTALES BASADOS EN LA CUOTA REDONDEADA ---
    // ¡MUY IMPORTANTE! Si la cuota se redondea, los totales del crédito cambian.
    // Debemos enviar al servidor los totales consistentes con la cuota redondeada.
    final double montoTotalARecuperarRedondeado =
        pagoCuotaRedondeado * numeroDePagos;
    final double interesTotalRedondeado =
        montoTotalARecuperarRedondeado - montoTotalCredito;

    // 6. --- CÁLCULO DE GARANTÍA ---
    String valorGarantiaString = "0%";
    double porcentajeGarantia = 0;
    if (garantia != null && garantia != "Sin garantía") {
      valorGarantiaString = garantia!;
      porcentajeGarantia =
          (double.tryParse(garantia!.replaceAll('%', '')) ?? 0) / 100.0;
    }
    final double montoGarantiaCalculado =
        montoTotalCredito * porcentajeGarantia;

    // 7. --- GENERACIÓN DE CALENDARIO DE PAGOS ---
    // 7. --- GENERACIÓN DE CALENDARIO DE PAGOS (CORREGIDO) ---
List<String> fechasDePago = [];

// ¡AQUÍ ESTÁ LA MODIFICACIÓN PRINCIPAL!
// 1. Se añade la fecha de desembolso como el elemento 0 del array.
fechasDePago.add(DateFormat('yyyy-MM-dd').format(fechaInicio));

// 2. Ahora se añaden los pagos (del 1 al 16) a la lista ya existente.
if (duracion.frecuenciaPago == "Quincenal") {
    // La función `calcularFechasDePago` ya devuelve la lista de pagos.
    // Usamos .addAll() para agregar esos pagos a nuestra lista.
    fechasDePago.addAll(calcularFechasDePago(fechaInicio, numeroDePagos));
} else { // Semanal
    // El bucle sigue calculando los 16 pagos correctamente.
    for (int i = 0; i < numeroDePagos; i++) {
        fechasDePago.add(
            DateFormat('yyyy-MM-dd').format(
                fechaInicio.add(Duration(days: (i + 1) * 7))
            ),
        );
    }
}

    // 8. --- CÁLCULO DE MONTOS INDIVIDUALES PARA LOS CLIENTES ---
    List<Map<String, dynamic>> clientesMontosIndividuales = [];
    for (var integrante in integrantes) {
      double capitalIndividual =
          montosIndividuales[integrante.idclientes] ?? 0.0;

      // El interés individual se calcula sobre el capital de cada uno.
      double interesIndividualPorPeriodo =
          capitalIndividual * (interesPorcentajePorPeriodo / 100.0);
      double capitalIndividualPorPeriodo = capitalIndividual / numeroDePagos;

      // Se calcula la cuota individual precisa.
      double cuotaIndividualPrecisa =
          capitalIndividualPorPeriodo + interesIndividualPorPeriodo;

      // Se calcula el total que pagará el individuo.
      double pagoTotalIndividual =
          capitalIndividual + (interesIndividualPorPeriodo * numeroDePagos);

      clientesMontosIndividuales.add({
        "iddetallegrupos": integrante.iddetallegrupos,
        "capitalIndividual": capitalIndividual,
        "periodoCapital": capitalIndividualPorPeriodo,
        "periodoInteres": interesIndividualPorPeriodo,
        "periodoInteresPorcentaje": tasa.mensual, // Tasa mensual de referencia
        "totalCapital": capitalIndividual,
        "totalIntereses": interesIndividualPorPeriodo * numeroDePagos,
        "capitalMasInteres":
            cuotaIndividualPrecisa, // Cuota individual por periodo
        "pagoTotal": pagoTotalIndividual, // Lo que el cliente pagará en total
      });
    }

    // 9. --- CONSTRUCCIÓN DEL OBJETO FINAL (PAYLOAD) ---
    // Se arma el mapa con todos los datos calculados.
    return {
      "idgrupos": grupo.idgrupos,
      "ti_mensual": tasa.mensual.toString(),
      "plazo": duracion.plazo,
      "frecuenciaPago": duracion.frecuenciaPago,
      "garantia": valorGarantiaString,
      "montoTotal": montoTotalCredito,
      "interesGlobal": interesGlobalCalculado,

      // --- Valores clave basados en el redondeo ---
      "pagoCuota": pagoCuotaRedondeado, // La cuota redondeada que se cobrará.
      "interesTotal": interesTotalRedondeado, // El interés total ajustado.
      "montoMasInteres":
          montoTotalARecuperarRedondeado, // El monto total a recuperar ajustado.

      "montoGarantia": montoGarantiaCalculado,
      "diaPago": diaPago,
      "fechasPago": fechasDePago,
      "clientesMontosInd": clientesMontosIndividuales,
    };
  }

  List<String> calcularFechasDePago(
    DateTime fechaInicio,
    int numeroDePagosQuincenales,
  ) {
    List<String> fechasDePago = [];
    DateTime fechaActual = _calcularPrimerPago(fechaInicio);

    for (int i = 0; i < numeroDePagosQuincenales; i++) {
      fechasDePago.add(DateFormat('yyyy-MM-dd').format(fechaActual));

      if (fechaActual.day == 15) {
        int anio = fechaActual.year;
        int mes = fechaActual.month;
        if (mes == 2) {
          // Febrero
          bool esBisiesto =
              (anio % 4 == 0 && anio % 100 != 0) || (anio % 400 == 0);
          fechaActual = DateTime(anio, mes, esBisiesto ? 29 : 28);
        } else if ([4, 6, 9, 11].contains(mes)) {
          // Meses con 30 días
          fechaActual = DateTime(anio, mes, 30);
        } else {
          // Meses con 31 días
          fechaActual = DateTime(
            anio,
            mes,
            30,
          ); // Regla de negocio: siempre día 30
        }
      } else {
        int siguienteMes = fechaActual.month == 12 ? 1 : fechaActual.month + 1;
        int siguienteAno =
            fechaActual.month == 12 ? fechaActual.year + 1 : fechaActual.year;
        fechaActual = DateTime(siguienteAno, siguienteMes, 15);
      }
    }
    return fechasDePago;
  }

  DateTime _calcularPrimerPago(DateTime fechaInicio) {
    int dia = fechaInicio.day;

    if (dia <= 10) {
      return DateTime(fechaInicio.year, fechaInicio.month, 15);
    } else if (dia > 10 && dia <= 25) {
      // CORREGIDO PARA FEBRERO Y FIN DE MES
      int anio = fechaInicio.year;
      int mes = fechaInicio.month;
      if (mes == 2) {
        bool esBisiesto =
            (anio % 4 == 0 && anio % 100 != 0) || (anio % 400 == 0);
        return DateTime(anio, mes, esBisiesto ? 29 : 28);
      } else if ([4, 6, 9, 11].contains(mes)) {
        return DateTime(anio, mes, 30);
      } else {
        return DateTime(anio, mes, 30); // Regla de negocio
      }
    } else {
      int siguienteMes = fechaInicio.month == 12 ? 1 : fechaInicio.month + 1;
      int siguienteAno =
          fechaInicio.month == 12 ? fechaInicio.year + 1 : fechaInicio.year;
      return DateTime(siguienteAno, siguienteMes, 15);
    }
  }

  //endregion
}
