// lib/screens/bitacora_screen.dart

import 'package:dropdown_button2/dropdown_button2.dart'; // <-- IMPORTANTE: Añadir esta importación
import 'package:finora_app/helpers/responsive_helpers.dart';
import 'package:finora_app/models/bitacora.dart';
import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/bitacora_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({Key? key}) : super(key: key);

  @override
  _BitacoraScreenState createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> {
  // --- Estado del Widget ---
  final BitacoraService _bitacoraService = BitacoraService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingUsers = true;
  bool _isLoadingBitacora = false;
  String? _errorMessage;

  List<Usuario> _usuarios = [];
  List<Bitacora> _bitacoraEntries = [];
  List<Bitacora> _filteredEntries = [];

  Usuario? _selectedUsuario;
  DateTime? _selectedDate;
  String _selectedActivityFilter = 'Todas las actividades';

  final List<String> _activityFilters = [
    'Todas las actividades',
    'Inicios de sesión',
    'Pagos',
    'Configuraciones',
    'Errores del sistema',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  // --- Lógica de Peticiones y Filtros ---

  Future<void> _fetchUsuarios() async {
    final response = await _bitacoraService.getUsuarios();
    if (mounted) {
      setState(() {
        _isLoadingUsers = false;
        if (response.success && response.data != null) {
          _usuarios = response.data!;
        } else {
          _errorMessage = response.error ?? 'Error al cargar usuarios.';
        }
      });
    }
  }

  Future<void> _fetchBitacora() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoadingBitacora = true;
      _errorMessage = null;
    });

    final response = await _bitacoraService.getBitacora(
      fecha: _selectedDate!,
      usuario: _selectedUsuario,
    );

    if (mounted) {
      setState(() {
        _isLoadingBitacora = false;
        if (response.success && response.data != null) {
          _bitacoraEntries = response.data!;
          _applyFilters();
        } else {
          _bitacoraEntries.clear();
          _filteredEntries.clear();
          _errorMessage = response.error ?? 'Error al cargar la bitácora.';
        }
      });
    }
  }

  void _applyFilters() {
    List<Bitacora> tempFiltered = List.from(_bitacoraEntries);

    if (_selectedActivityFilter != 'Todas las actividades') {
      tempFiltered =
          tempFiltered.where((item) {
            String accion = item.accion.toLowerCase();
            switch (_selectedActivityFilter) {
              case 'Inicios de sesión':
                return accion.contains('inicio') ||
                    accion.contains('login') ||
                    accion.contains('sesión');
              case 'Pagos':
                return accion.contains('pago') ||
                    accion.contains('transacción') ||
                    accion.contains('cobro');
              case 'Configuraciones':
                return accion.contains('actualiz') ||
                    accion.contains('configur') ||
                    accion.contains('permiso');
              case 'Errores del sistema':
                return accion.contains('error') ||
                    accion.contains('fallo') ||
                    accion.contains('excepción');
              default:
                return true;
            }
          }).toList();
    }

    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      tempFiltered =
          tempFiltered.where((entry) {
            return entry.nombreCompleto.toLowerCase().contains(searchTerm) ||
                entry.accion.toLowerCase().contains(searchTerm) ||
                (entry.nombreAfectado?.toLowerCase().contains(searchTerm) ??
                    false);
          }).toList();
    }

    setState(() {
      _filteredEntries = tempFiltered;
    });
  }

  Future<void> _selectDate() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder:
          (context, child) =>
              Theme(data: themeProvider.datePickerTheme, child: child!),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- Construcción de la Interfaz (UI) ---

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Container(
      color: colors.backgroundPrimary,
      child: Column(
        children: [
          if (context.isMobile) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
              child: Text(
                'Bitácora',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
          _buildFilterBar(colors),
          Expanded(child: _buildContentBody(colors)),
        ],
      ),
    );
  }

  // --- WIDGETS DE FILTROS CON ESTILOS COMBINADOS ---

  Widget _buildFilterBar(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FILA 1: Dropdowns con nuevo estilo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildUserDropdown(colors)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildActivityDropdown(colors)),
            ],
          ),
          const SizedBox(height: 16),

          // FILA 2: Botones con el estilo original
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(  
                    _selectedDate == null
                        ? 'Seleccionar Fecha'
                        : DateFormat('d MMM y', 'es_ES').format(_selectedDate!),
                  ),
                  onPressed: _selectDate,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.brandPrimary,
                    backgroundColor: colors.backgroundSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('Consultar'),
                  onPressed: _selectedDate == null ? null : _fetchBitacora,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // TextField de búsqueda con el nuevo estilo
          if (_bitacoraEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildSearchTextField(colors),
            ),
        ],
      ),
    );
  }

  Widget _buildUserDropdown(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'Usuario',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 40,
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<Usuario>(
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              isExpanded: true,
              value: _selectedUsuario,
              hint: Text(
                _isLoadingUsers ? 'Cargando...' : 'Todos',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              items: [
                const DropdownMenuItem<Usuario>(
                  value: null,
                  child: Text('Todos los usuarios'),
                ),
                ..._usuarios.map(
                  (user) => DropdownMenuItem(
                    value: user,
                    child: Text(
                      user.nombreCompleto,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged:
                  _isLoadingUsers
                      ? null
                      : (value) {
                        setState(() {
                          _selectedUsuario = value;
                        });
                      },
              buttonStyleData: const ButtonStyleData(
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
              iconStyleData: IconStyleData(
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: colors.textSecondary.withOpacity(0.7),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colors.backgroundCard,
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(height: 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityDropdown(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'Actividad',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 40,
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              isExpanded: true,
              value: _selectedActivityFilter,
              hint: Text(
                'Seleccionar',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary.withOpacity(0.7),
                ),
              ),
              items:
                  _activityFilters
                      .map(
                        (filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(filter, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedActivityFilter = value;
                  });
                  if (_bitacoraEntries.isNotEmpty) {
                    _applyFilters();
                  }
                }
              },
              buttonStyleData: const ButtonStyleData(
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
              iconStyleData: IconStyleData(
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: colors.textSecondary.withOpacity(0.7),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colors.backgroundCard,
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(height: 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchTextField(dynamic colors) {
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
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Filtrar resultados...',
          hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.7)),
          prefixIcon: Icon(Icons.filter_list, color: colors.textSecondary),
          filled: true,
          fillColor: Colors.transparent, // El color lo da el container
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // --- RESTO DEL CÓDIGO (SIN CAMBIOS) ---

  Widget _buildContentBody(dynamic colors) {
    if (_isLoadingBitacora) {
      return Center(
        child: CircularProgressIndicator(color: colors.brandPrimary),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_bitacoraEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 40, color: colors.textSecondary),
            const SizedBox(height: 10),
            Text(
              'Usa los filtros y presiona "Consultar"',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }
    if (_filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40, color: colors.textSecondary),
            const SizedBox(height: 10),
            Text(
              'No se encontraron registros',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = _filteredEntries[index];
        return _buildBitacoraCard(entry, colors);
      },
    );
  }

  Widget _buildBitacoraCard(Bitacora entry, dynamic colors) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.backgroundSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _getIconColorForAction(
                entry.accion,
                colors,
              ).withOpacity(0.1),
              child: Icon(
                _getIconForAction(entry.accion),
                color: _getIconColorForAction(entry.accion, colors),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${entry.nombreCompleto}: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: entry.accion,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (entry.nombreAfectado != null &&
                      entry.nombreAfectado != 'N/A') ...[
                    const SizedBox(height: 6),
                    Text(
                      'Afectado: ${entry.nombreAfectado}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    DateFormat(
                      'd MMM y, hh:mm a',
                      'es_ES',
                    ).format(entry.createAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary?.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
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

Color _getIconColorForAction(String action, dynamic colors) {
  action = action.toLowerCase();

  // 'crea' cubre "creó" y "creación". 'agreg' cubre "agregaron".
  if (action.contains('crea') || action.contains('agreg') || action.contains('renov')) {
    return Colors.green;
  }

  // Nueva condición para los pagos.
  if (action.contains('pago')) {
    return Colors.blue; // Puedes cambiarlo por Colors.orange si prefieres
  }

  // La eliminación ya estaba cubierta y funcionará bien.
  if (action.contains('elimin')) {
    return Colors.red;
  }
  
  if (action.contains('actualiz')) {
    return Colors.blue;
  }

  if (action.contains('inicio') || action.contains('login')) {
    return colors.brandPrimary ?? Colors.purple;
  }

  // Color por defecto para cualquier otra acción.
  return Colors.grey;
}

// La función de los iconos no necesita cambios, ya funciona bien.
IconData _getIconForAction(String action) {
  action = action.toLowerCase();
  if (action.contains('creo') || action.contains('agreg')) {
    return Icons.add_circle_outline;
  }
  if (action.contains('actualiz')) {
    return Icons.edit_outlined;
  }
  if (action.contains('elimino')) {
    return Icons.remove_circle_outline;
  }
  if (action.contains('inicio') || action.contains('login')) {
    return Icons.login;
  }
  if (action.contains('pago')) {
    return Icons.payment; // Este ya lo tenías, ¡perfecto!
  }
  return Icons.info_outline;
}
}
