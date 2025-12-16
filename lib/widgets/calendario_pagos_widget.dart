// lib/widgets/calendario_pagos.dart (o la ruta donde tengas tu widget)

// <<< NUEVO >>> Importa los modelos y servicios que creamos
import 'dart:convert';

import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/ip.dart';
import 'package:finora_app/models/agenda_item.dart';
import 'package:finora_app/services/agenda_service.dart';

// <<< MODIFICADO >>> Asegúrate que estas rutas son correctas para tu proyecto
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/config_service.dart';
import 'package:finora_app/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

class CalendarioPagos extends StatefulWidget {
  final bool isDarkMode;

  const CalendarioPagos({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<CalendarioPagos> createState() => _CalendarioPagosState();
}

class _CalendarioPagosState extends State<CalendarioPagos> {
  DateTime selectedDate = DateTime.now();
  CalendarView currentView = CalendarView.daily;
  DateTime currentMonth = DateTime.now();

  // <<< NUEVO >>> Variables de estado para manejar los datos de la API
  final AgendaService _agendaService = AgendaService();
  Map<DateTime, List<PagoGrupo>> _pagosDelMes = {};
  bool _isLoading = true;
  String? _errorMessage;
  // Se elimina la variable estática 'pagosEjemplo'

   // --- AÑADE ESTAS DOS LÍNEAS ---
  int _startOfWeekDay = DateTime.monday; // Valor por defecto: Lunes
  bool _isLoadingDiaCorte = true;
  // ------------------------------

  final AppColors colors = AppColors();

  // --- AÑADE ESTA LÍNEA ---
  final ConfigService _configService = ConfigService();
  // --------------------------

  @override
  void initState() {
    super.initState();
     // --- AÑADE LA LLAMADA A LA NUEVA FUNCIÓN ---
    _fetchDiaCorteYDatos();
    // <<< NUEVO >>> Llamamos a la API para cargar los datos del mes actual al iniciar el widget
    //_fetchAgendaData();
  }



  // --- REEMPLAZA TU FUNCIÓN EXISTENTE CON ESTA ---

  Future<void> _fetchDiaCorteYDatos() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isLoadingDiaCorte = true;
      _errorMessage = null;
    });

    // Llamamos a nuestro nuevo servicio
    final response = await _configService.getDiaCorte();

    if (response.success && response.data != null) {
      // Si la llamada fue exitosa y obtuvimos un día
      if (mounted) {
        setState(() {
          _startOfWeekDay = _parseDiaCorte(response.data!);
        });
      }
    } else {
      // Si falló o no vino el dato, el valor por defecto (_startOfWeekDay = DateTime.monday) se mantiene.
      // El ApiService ya se encargó de loguear el error si lo hubo.
    }

    // El resto de la lógica no cambia
    if (mounted) {
      setState(() => _isLoadingDiaCorte = false);
      // Una vez que tenemos el día de corte (o el defecto), cargamos la agenda.
      _fetchAgendaData();
    }
  }

  int _parseDiaCorte(String dia) {
    switch (dia.toLowerCase()) {
      case 'lunes':
        return DateTime.monday;
      case 'martes':
        return DateTime.tuesday;
      case 'miercoles':
        return DateTime.wednesday;
      case 'jueves':
        return DateTime.thursday;
      case 'viernes':
        return DateTime.friday;
      case 'sábado':
        return DateTime.saturday;
      case 'domingo':
        return DateTime.sunday;
      default:
        return DateTime.monday; // Fallback seguro
    }
  }

  // <<< NUEVO >>> Método para obtener los datos desde AgendaService y procesarlos
  Future<void> _fetchAgendaData() async {
    if (!mounted) return;
    /* setState(() {
      _isLoading = true;
      _errorMessage = null;
    }); */

    try {
      final List<AgendaItem> items = await _agendaService.getAgendaDelMes(
        currentMonth.year,
        currentMonth.month,
      );

      final Map<DateTime, List<PagoGrupo>> newPagos = {};
      for (var item in items) {
        // Normalizamos la fecha a medianoche para usarla como clave en el mapa
        final dateKey = DateTime(
          item.fechasPago.year,
          item.fechasPago.month,
          item.fechasPago.day,
        );

        // <<< CAMBIO CLAVE AQUÍ >>>
        // Ahora usamos los datos reales del 'item' de la API
        final pago = PagoGrupo(
          nombreGrupo: item.nombreGrupo,
          monto: item.pagoPeriodo,
          tipo: item.tipoGrupo, // Usamos el tipo real que viene de la API
          detalles: item.detalles, // Añadimos los detalles
          estado: item.estado, // Añadimos el estado
          semanaPago: item.semanaPago, // Añadimos la semana de pago
        );

        if (newPagos.containsKey(dateKey)) {
          newPagos[dateKey]!.add(pago);
        } else {
          newPagos[dateKey] = [pago];
        }
      }

      if (!mounted) return;
      setState(() {
        _pagosDelMes = newPagos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;
    final bool isSmallScreen2 = size.width < 800;
    final bool isSmallScreen3 = size.width < 1600;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: colors.backgroundCard,
        ),
        child: Column(
          children: [
            _buildHeader(isSmallScreen),
            _buildViewSelector(isSmallScreen),
            // <<< MODIFICADO >>> Muestra un indicador de carga, un mensaje de error o el calendario
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? _buildErrorView()
                      : _buildCalendarContent(isSmallScreen, isSmallScreen2, isSmallScreen3),
            ),
          ],
        ),
      ),
    );
  }

  // <<< NUEVO >>> Widget para mostrar en caso de error en la API
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 50),
            const SizedBox(height: 16),
            Text(
              'Error al cargar la agenda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              onPressed: _fetchAgendaData,
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (El resto de tus widgets de construcción no cambian de lógica, solo de donde leen los datos)

  Widget _buildHeader(bool isSmallScreen) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      padding: EdgeInsets.only(
        left: isSmallScreen ? 11 : 20,
        right: isSmallScreen ? 11 : 20,
        top: 8,
        bottom: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousPeriod,
            icon: Icon(
              Icons.chevron_left,
              color: isDarkMode ? Colors.white : Colors.black,
              size: isSmallScreen ? 20 : 28,
            ),
          ),
          Column(
            children: [
              Text(
                'Agenda de Pagos',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getHeaderTitle(),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: isSmallScreen ? 11 : 12,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _nextPeriod,
            icon: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white : Colors.black,
              size: isSmallScreen ? 20 : 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isSmallScreen ? 4 : 15,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildViewButton(
            'Día',
            CalendarView.daily,
            Icons.today,
            isSmallScreen,
          ),
          _buildViewButton(
            'Semana',
            CalendarView.weekly,
            Icons.view_week,
            isSmallScreen,
          ),
          _buildViewButton(
            'Mes',
            CalendarView.monthly,
            Icons.calendar_month,
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(
    String title,
    CalendarView view,
    IconData icon,
    bool isSmallScreen,
  ) {
    final isSelected = currentView == view;
    return GestureDetector(
      onTap: () => setState(() => currentView = view),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 4 : 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color:
              isSelected ? const Color(0xFF5162F6) : colors.backgroundCardDark,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSmallScreen ? 14 : 18,
              color:
                  isSelected
                      ? Colors.white
                      : (widget.isDarkMode ? Colors.white70 : Colors.grey[600]),
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                color:
                    isSelected
                        ? Colors.white
                        : (widget.isDarkMode
                            ? Colors.white70
                            : Colors.grey[600]),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarContent(bool isSmallScreen, bool isSmallScreen2, bool isSmallScreen3) {
    switch (currentView) {
      case CalendarView.daily:
        return _buildDailyView(isSmallScreen);
      case CalendarView.weekly:
        return _buildWeeklyView(isSmallScreen);
      case CalendarView.monthly:
        return _buildMonthlyView(isSmallScreen, isSmallScreen2, isSmallScreen3);
    }
  }

   Widget _buildMonthlyView(bool isSmallScreen, bool isSmallScreen2, bool isSmallScreen3) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 4 : 8,
      ),
      child: Column(
        children: [
          Row(
            children:
                ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                              fontSize: isSmallScreen ? 10 : 12,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          SizedBox(height: isSmallScreen ? 4 : 10),
          // Expanded sigue definiendo el área disponible para el calendario
          Expanded(
            // <<< CAMBIO 1: Añadimos un SingleChildScrollView >>>
            // Este widget es el que permitirá el scroll sin estirar el contenido.
            child: SingleChildScrollView(
              child: GridView.builder(
                // <<< CAMBIO 2: Devolvemos estas dos propiedades >>>
                // shrinkWrap le dice al GridView que sea tan alto como su contenido.
                shrinkWrap: true,
                // physics evita un conflicto de scroll entre el GridView y el SingleChildScrollView.
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  // <<< CAMBIO 3: Restauramos el aspect ratio original que te gustaba >>>
                  childAspectRatio: isSmallScreen2 ? 1.4 : 1.0,
                  crossAxisSpacing: isSmallScreen2 ? 2 : 10,
                  mainAxisSpacing: isSmallScreen2 ? 2 : 10,
                ),
                itemCount:
                    _getDaysInMonth(currentMonth) +
                    _getFirstDayOfMonth(currentMonth) -
                    1,
                itemBuilder: (context, index) {
                  final firstDay = _getFirstDayOfMonth(currentMonth);
                  if (index < firstDay - 1) {
                    return Container(); // Espacios vacíos al inicio del mes
                  }
                  final day = index - firstDay + 2;
                  final date = DateTime(
                    currentMonth.year,
                    currentMonth.month,
                    day,
                  );
                  final pagos = _pagosDelMes[date] ?? [];
                  final isSelected = _isSameDay(date, selectedDate);
                  final isToday = _isSameDay(date, DateTime.now());

                  return GestureDetector(
                    onTap: () => setState(() => selectedDate = date),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color:
                            isSelected
                                ? const Color(0xFF5162F6)
                                : isToday
                                ? const Color(0xFF5162F6).withOpacity(0.7)
                                : null,
                        border:
                            (isSelected)
                                ? Border.all(color: const Color(0xFF6BC950), width: 1.5)
                                : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 14,
                              color:
                                  (isToday || isSelected)
                                      ? Colors.white
                                      : (widget.isDarkMode
                                          ? Colors.white
                                          : Colors.black87),
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (pagos.isNotEmpty)
                            Container(
                              width: isSmallScreen ? 4 : 6,
                              height: isSmallScreen ? 4 : 6,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : const Color(0xFF6BC950),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 10),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: _buildSummaryBar(isSmallScreen, isSmallScreen3),
          ),
        ],
      ),
    );
  }


  // <<< CAMBIO 3: Widget de resumen renombrado y con lógica condicional >>>
   // <<< MODIFICADO: Widget de resumen con lógica de "A recibir" y "Pagado" >>>
   // <<< MODIFICADO: Widget de resumen con lógica condicional para la disposición >>>
   // <<< MODIFICADO: Ahora recibe isSmallScreen2 y la condición usa esta variable >>>
  Widget _buildSummaryBar(bool isSmallScreen, bool isSmallScreen3) { // <<< CAMBIO 1: Nueva firma
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    colors.setDarkMode(isDarkMode);

    final pagos =
        _pagosDelMes[DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        )] ??
        [];

    if (pagos.isEmpty) {
      // ... (código sin cambios)
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colors.backgroundCardDark,
        ),
        child: Text(
          'No hay pagos para ${DateFormat('d MMM', 'es_ES').format(selectedDate)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
      );
    }
    
    // ... (lógica de cálculo de totales sin cambios) ...
    const estadosPagados = ['pagado', 'pagado para renovacion', 'en abonos', 'garantia pagada'];
    final totalARecibir = pagos
        .where((pago) => pago.estado.toLowerCase() != 'desembolso')
        .fold<double>(0, (sum, pago) => sum + pago.monto);
    final totalPagado = pagos
        .where((pago) => estadosPagados.contains(pago.estado.toLowerCase()))
        .fold<double>(0, (sum, pago) => sum + pago.monto);

    final summaryText = Text(
      '${DateFormat('d MMM', 'es_ES').format(selectedDate)}: ${pagos.length} movimiento${pagos.length > 1 ? 's' : ''}',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: isSmallScreen ? 12 : 13,
        color: widget.isDarkMode ? Colors.white : Colors.black87,
      ),
      overflow: TextOverflow.ellipsis,
    );

    final detailsButton = TextButton(
      // ... (código del botón sin cambios)
      onPressed: () => setState(() => currentView = CalendarView.daily),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 12,
          vertical: isSmallScreen ? 8 : 8,
        ),
        minimumSize: isSmallScreen ? Size.zero : null,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: colors.brandPrimaryTheme,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        'Ver detalles',
        style: TextStyle(
          color: colors.brandPrimaryThemeText,
          fontWeight: FontWeight.w600,
          fontSize: isSmallScreen ? 11 : 11,
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 4 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.backgroundCard,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            // <<< CAMBIO 2: La condición ahora usa isSmallScreen2 >>>
            child: (isSmallScreen3 && currentView == CalendarView.monthly)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      summaryText,
                      const SizedBox(height: 8),
                      detailsButton,
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: summaryText),
                      if (currentView == CalendarView.monthly) ...[
                        const SizedBox(width: 8),
                        detailsButton,
                      ],
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          // ... (resto del widget sin cambios)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A recibir: ',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                  ),
                  Text(
                    formatCurrency(totalARecibir),
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 13 : 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pagado: ',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                  ),
                  Text(
                    formatCurrency(totalPagado),
                    style: TextStyle(
                      color: const Color(0xFF51BF33),
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 13 : 15,
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDailyView(bool isSmallScreen) {
    // <<< MODIFICADO >>> Usa los datos de la API
    final pagosDelDia =
        _pagosDelMes[DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        )] ??
        [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(selectedDate),
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                pagosDelDia.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay pagos programados',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: pagosDelDia.length,
                      itemBuilder:
                          (context, index) =>
                              _buildPagoCard(pagosDelDia[index]),
                    ),
          ),
          const SizedBox(height: 8),
          Center(
            child: _buildSummaryBar(isSmallScreen, false),
          ), // <-- BARRA AÑADIDA AQUÍ
        ],
      ),
    );
  }

   // <<< MODIFICADO >>>
  Widget _buildWeeklyView(bool isSmallScreen) {
    // Usamos la nueva función para calcular el inicio de la semana (Martes)
    final startOfWeek = _getStartOfWeek(selectedDate);
    
    // El resto del código usa `startOfWeek`, por lo que se adaptará automáticamente.
    final pagosDelDiaSeleccionado =
        _pagosDelMes[DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        )] ??
        [];

    Widget buildDayItem(DateTime day) {
      final pagosEnEsteDia =
          _pagosDelMes[DateTime(day.year, day.month, day.day)] ?? [];
      final bool isSelected = _isSameDay(day, selectedDate);

      return GestureDetector(
          onTap: () {
          // Guardamos el mes anterior para comparar
          final prevMonth = currentMonth.month;
          
          setState(() {
            selectedDate = day;
            
            // <<< MEJORA RECOMENDADA >>>
            // Si al tocar el día cambiamos de mes (ej. de Nov a Dic),
            // actualizamos currentMonth y recargamos la API.
            if (day.month != prevMonth) {
              currentMonth = DateTime(day.year, day.month);
              _fetchAgendaData(); // Recarga los pagos del nuevo mes
            }
          });
        },
        child: Container(
          width: 45,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color(0xFF5162F6)
                    : colors.backgroundCardDark2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('E', 'es_ES').format(day).substring(0, 3),
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: isSelected ? Colors.white70 : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('d').format(day),
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 16,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected
                          ? Colors.white
                          : (widget.isDarkMode
                              ? Colors.white70
                              : Colors.black87),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                height: 5,
                width: 5,
                decoration: BoxDecoration(
                  color:
                      pagosEnEsteDia.isNotEmpty
                          ? (isSelected
                              ? Colors.white
                              : const Color(0xFF6BC950))
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              // El título se calcula correctamente: Martes (startOfWeek) a Lunes (startOfWeek + 6 días)
              'Semana del ${DateFormat('d MMM', 'es_ES').format(startOfWeek)} al ${DateFormat('d MMM yyyy', 'es_ES').format(startOfWeek.add(const Duration(days: 6)))}',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: isSmallScreen ? 50 : 80,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child:
                isSmallScreen
                    ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        // El bucle ahora genera de Martes a Lunes
                        final day = startOfWeek.add(Duration(days: index));
                        return buildDayItem(day);
                      },
                    )
                    : Row(
                      children: List.generate(7, (index) {
                         // El bucle ahora genera de Martes a Lunes
                        final day = startOfWeek.add(Duration(days: index));
                        return Expanded(child: buildDayItem(day));
                      }),
                    ),
          ),
          // ... (el resto del widget _buildWeeklyView no cambia)
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child:
                  pagosDelDiaSeleccionado.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay pagos programados para este día',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: pagosDelDiaSeleccionado.length,
                        itemBuilder:
                            (context, index) =>
                                _buildPagoCard(pagosDelDiaSeleccionado[index]),
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: _buildSummaryBar(isSmallScreen, false),
          ),
        ],
      ),
    );
  }

  // <<< NUEVO >>> Pequeña función de ayuda para obtener el color según el estado
  Color _getColorForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange.shade700;
      case 'pagado':
        return Colors.green.shade600;
      case 'pagado para renovacion':
        return Colors.green.shade600;
      case 'garantia pagada':
        return Colors.yellow.shade700;
      case 'vencido':
        return Colors.red.shade700;
      case 'en abonos':
        return Colors.blue.shade500;
      case 'desembolso':
        return Colors.teal;
      default:
        return Colors.grey.shade600;
    }
  }

  // <<< MODIFICADO: Tarjeta de pago con más información >>>
  
  // <<< MODIFICADO: Tarjeta de pago con lógica para no mostrar monto en desembolsos >>>
  Widget _buildPagoCard(PagoGrupo pago) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    final bool isGrupal = pago.tipo.toLowerCase().contains('grupal');
    final Color tipoColor =
        isGrupal ? const Color(0xFF5162F6) : const Color(0xFF4ECDC4);
    final IconData tipoIcon = isGrupal ? Icons.group : Icons.person;

    // <<< NUEVO: Variable para controlar si es un desembolso >>>
    final bool esDesembolso = pago.estado.toLowerCase() == 'desembolso';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.backgroundCardDark,
        border: Border(left: BorderSide(width: 5, color: tipoColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(tipoIcon, color: tipoColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pago.nombreGrupo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 11 : 12,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  // <<< MODIFICADO: Mostramos el monto original en los detalles si es desembolso >>>
                /*   esDesembolso 
                    ? 'Monto de la ficha: ${formatCurrency(pago.monto)}' 
                    : '${pago.detalles} • Pago ${pago.semanaPago}', */
                    '${pago.detalles} • Pago ${pago.semanaPago}',
                  style: TextStyle(
                    color:
                        widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center, // Centra el contenido verticalmente
            children: [
              // <<< MODIFICADO: Condición para mostrar el monto >>>
              // Si NO es un desembolso, muestra el monto del pago.
              // Si es un desembolso, no muestra nada aquí, para no confundir.
              if (!esDesembolso)
                Text(
                  formatCurrency(pago.monto),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 12 : 12,
                    color: const Color(0xFF51BF33),
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getColorForEstado(pago.estado).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pago.estado,
                  style: TextStyle(
                    color: _getColorForEstado(pago.estado),
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  
 String _getHeaderTitle() {
    switch (currentView) {
      case CalendarView.daily:
        return DateFormat('MMMM yyyy', 'es_ES').format(selectedDate);
      
      case CalendarView.weekly:
        // <<< CORRECCIÓN >>>
        // Antes: final startOfWeek = _getStartOfWeek(selectedDate);
        // Antes: return DateFormat('MMMM yyyy', 'es_ES').format(startOfWeek);
        
        // Ahora: Usamos selectedDate directamente. 
        // Si tocas el 1 de dic, mostrará Diciembre. Si tocas el 27 de nov, mostrará Noviembre.
        return DateFormat('MMMM yyyy', 'es_ES').format(selectedDate);
        
      case CalendarView.monthly:
        return DateFormat('MMMM yyyy', 'es_ES').format(currentMonth);
    }
  }

  // <<< MODIFICADO >>> Llama a _fetchAgendaData() al cambiar de mes
   // <<< MODIFICADO Y CORREGIDO >>> Llama a _fetchAgendaData() al cambiar de mes en CUALQUIER vista
  void _previousPeriod() {
    // Guardamos la fecha actual para comparar después si el mes cambió.
    final oldDate = selectedDate;

    setState(() {
      DateTime newDate; // Usaremos esta variable para la nueva fecha seleccionada

      switch (currentView) {
        case CalendarView.daily:
          newDate = selectedDate.subtract(const Duration(days: 1));
          selectedDate = newDate;
          // Comprobamos si el mes ha cambiado
          if (newDate.month != oldDate.month) {
            currentMonth = DateTime(newDate.year, newDate.month);
            _fetchAgendaData(); // ¡Recargamos los datos del nuevo mes!
          }
          break;

        case CalendarView.weekly:
          newDate = selectedDate.subtract(const Duration(days: 7));
          selectedDate = newDate;
          // Comprobamos si el mes ha cambiado
          if (newDate.month != oldDate.month) {
            currentMonth = DateTime(newDate.year, newDate.month);
            _fetchAgendaData(); // ¡Recargamos los datos del nuevo mes!
          }
          break;

        case CalendarView.monthly:
          currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
          // Actualizamos selectedDate para que no quede en un día inválido (ej. 31 de Febrero)
          // y para que se mantenga dentro del mes visible.
          selectedDate = DateTime(
            currentMonth.year,
            currentMonth.month,
            // Usamos 1 para asegurar que es un día válido, podrías mantener el día si quisieras
            // pero esto es más seguro.
            1, 
          );
          _fetchAgendaData(); // Recargar datos para el nuevo mes
          break;
      }
    });
  }

  // <<< MODIFICADO Y CORREGIDO >>> Llama a _fetchAgendaData() al cambiar de mes en CUALQUIER vista
  void _nextPeriod() {
    // Guardamos la fecha actual para comparar después si el mes cambió.
    final oldDate = selectedDate;
    
    setState(() {
      DateTime newDate; // Usaremos esta variable para la nueva fecha seleccionada

      switch (currentView) {
        case CalendarView.daily:
          newDate = selectedDate.add(const Duration(days: 1));
          selectedDate = newDate;
          // Comprobamos si el mes ha cambiado
          if (newDate.month != oldDate.month) {
            currentMonth = DateTime(newDate.year, newDate.month);
            _fetchAgendaData(); // ¡Recargamos los datos del nuevo mes!
          }
          break;
          
        case CalendarView.weekly:
          newDate = selectedDate.add(const Duration(days: 7));
          selectedDate = newDate;
          // Comprobamos si el mes ha cambiado
          if (newDate.month != oldDate.month) {
            currentMonth = DateTime(newDate.year, newDate.month);
            _fetchAgendaData(); // ¡Recargamos los datos del nuevo mes!
          }
          break;

        case CalendarView.monthly:
          currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
          // Actualizamos selectedDate para que se mantenga dentro del mes visible.
          selectedDate = DateTime(
            currentMonth.year,
            currentMonth.month,
            1,
          );
          _fetchAgendaData(); // Recargar datos para el nuevo mes
          break;
      }
    });
  }

    // <<< NUEVO >>> Función de ayuda para obtener el Martes de inicio de semana
  // <<< MODIFICADO >>> Ahora es dinámica y usa el día de corte configurado
DateTime _getStartOfWeek(DateTime date) {
  // DateTime.weekday: Lunes=1, Martes=2, ..., Domingo=7
  // _startOfWeekDay tiene el valor numérico del día que queremos que sea el inicio.
  int daysToSubtract = (date.weekday - _startOfWeekDay + 7) % 7;
  return date.subtract(Duration(days: daysToSubtract));
}


  // Métodos de ayuda (sin cambios)
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday;
  }
}

// Clases de ayuda
enum CalendarView { daily, weekly, monthly }

// <<< MODIFICADO: Añadimos más campos para mostrar en la UI >>>
class PagoGrupo {
  final String nombreGrupo;
  final double monto;
  final String tipo;
  final String detalles; // ej: "CICLO-01"
  final String estado; // ej: "Pendiente"
  final int semanaPago; //ej: "14" si quieres mostrar la semana

  PagoGrupo({
    required this.nombreGrupo,
    required this.monto,
    required this.tipo,
    required this.detalles,
    required this.estado,
    required this.semanaPago,
  });
}
