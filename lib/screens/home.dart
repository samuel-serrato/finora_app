import 'dart:async';
import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/widgets/calendario_pagos_widget.dart';
import 'package:finora_app/widgets/grafica_pagos_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/app_logger.dart';

// NUEVO: Importamos el paquete de gráficas
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String tipoUsuario;

  const HomeScreen({
    Key? key,
    required this.username,
    required this.tipoUsuario,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  HomeData? homeData;
  bool isLoading = true;
  String errorMessage = '';
  bool _isRefreshing = false;
  final ApiService _apiService = ApiService();

  final AppColors colors = AppColors();

  // Variables para el control del menú móvil
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // CAMBIO: Inicializamos el TabController con 2 tabs en lugar de 3
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // No es necesario comprobar 'indexIsChanging' si solo actualizamos el estado
      if (_tabController.index != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.setContext(context);
      _fetchHomeData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHomeData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final response = await _apiService.get<HomeData>(
      '/api/v1/home',
      parser: (json) => HomeData.fromJson(json),
    );

    if (mounted) {
      setState(() {
        isLoading = false;
        if (response.success) {
          homeData = response.data;
          AppLogger.log('📦 Datos cargados correctamente');
        } else {
          errorMessage = response.error ?? 'Error desconocido';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    colors.setDarkMode(isDarkMode);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: RefreshIndicator(
        onRefresh: _fetchHomeData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return _buildMobileLayout();
            } else {
              return _buildDesktopLayout();
            }
          },
        ),
      ),
    );
  }

  // Layout móvil mejorado con menú de tabs
  Widget _buildMobileLayout() {
    const bool isSmallScreen = true;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return SafeArea(
      child: Column(
        children: [
          // Parte superior fija (no scroll)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               /*  welcomeCard(),
                const SizedBox(height: 14), */
                _buildSummaryHeader(),
                const SizedBox(height: 0),
                statCardsList(isSmallScreen: true, crossAxisCount: 2),
                const SizedBox(height: 16),
                // Menú de tabs personalizado
                _buildMobileTabMenu(),
              ],
            ),
          ),
          // Contenido que cambia según el tab seleccionado
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: _buildMobileTabContent(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para el menú de tabs en móvil
  Widget _buildMobileTabMenu() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.textSecondary.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,

        // SOLUCIÓN: Añade esta línea para hacer el divisor transparente
        dividerColor: Colors.transparent,

        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colors.brandPrimary,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: colors.textSecondary,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(
            // Opcional: Ajusté la altura para que coincida con el container
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 14),
                SizedBox(width: 8),
                Text('Agenda'),
              ],
            ),
          ),
          Tab(
            // Opcional: Ajusté la altura para que coincida con el container
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 14),
                SizedBox(width: 8),
                Text('Gráficas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget que muestra el contenido según el tab seleccionado
  // Widget que muestra el contenido según el tab seleccionado
  // Widget que muestra el contenido según el tab seleccionado
  Widget _buildMobileTabContent(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
      child: IndexedStack(
        index: _selectedTabIndex,
        children: [
          // Tab 0: Calendario de Pagos
          // Este widget ya está diseñado para ser flexible.
          CalendarioPagos(isDarkMode: isDarkMode),

          // Tab 0: Gráfica
          // <<< ¡AQUÍ ESTÁ EL CAMBIO! >>>
          // Simplemente quitamos el SizedBox que limitaba la altura.
          // Ahora la gráfica se expandirá para llenar el espacio disponible.
          GraficaPagosWidget(colors: colors),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    const bool isSmallScreen = false;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- COLUMNA IZQUIERDA ---
            Expanded(flex: 2, child: _buildLeftColumn(isSmallScreen)),
            const SizedBox(width: 24),

            // --- COLUMNA DERECHA ---
            Expanded(flex: 1, child: _buildRightColumn(isSmallScreen)),
          ],
        ),
      ),
    );
  }

  /// Widget que construye toda la columna izquierda del dashboard
  Widget _buildLeftColumn(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Saludo de bienvenida (tamaño fijo)
     /*    welcomeCard(), */
     /*    const SizedBox(height: 12), */

        // 2. Tarjetas de resumen (tamaño fijo)
        statCardsList(isSmallScreen: false, crossAxisCount: 5),
        const SizedBox(height: 12),

        // 3. Fila expandida para contener las dos gráficas
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gráfica de la izquierda (ocupa la mitad del espacio)
              // <<< CAMBIO AQUÍ >>>
              // Reemplazamos la gráfica estática por la nueva gráfica dinámica
              Expanded(child: GraficaPagosWidget(colors: colors)),
              /*  const SizedBox(width: 24),
              Expanded(
                child: SalesPerformanceChart(colors: colors, isExpanded: true),
              ), */
            ],
          ),
        ),
      ],
    );
  }

  /// Widget que construye toda la columna derecha del dashboard
  Widget _buildRightColumn(bool isSmallScreen) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Column(
      children: [
        // 1. Agenda de Pagos
        Expanded(child: CalendarioPagos(isDarkMode: isDarkMode)),
        // Si necesitas más widgets en esta columna, puedes agregarlos aquí.
      ],
    );
  }

  Widget _buildSummaryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_isRefreshing)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget welcomeCard() {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Container(
      width: double.infinity,
      /* decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: colors.homeWelcomeGradient,
      ), */
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 0 : 18,
        horizontal: isSmallScreen ? 4 : 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  "Hola, ${widget.username}!",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 22,
                    fontWeight: FontWeight.w600,
                    color: colors.blackWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          /* const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now()),
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 14,
              color: colors.whiteWhite.withOpacity(0.7),
            ),
          ), */
        ],
      ),
    );
  }

  Widget statCardsList({
    required bool isSmallScreen,
    required int crossAxisCount,
  }) {
    if (isLoading && !_isRefreshing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.homeErrorIcon),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchHomeData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final cardData = [
      {
        'title': 'Créditos Activos',
        'value': homeData?.creditosActFin.first.creditos_activos ?? '0',
        'icon': Icons.group_work_rounded,
        'color': AppColors.statCardCreditos,
      },
      {
        'title': 'Acumulado Semanal',
        'value':
            '\$${formatearNumero(double.tryParse(homeData?.sumaPagos.first.sumaDepositos ?? '0') ?? 0.0)}',
        'icon': Icons.payments,
        'color': AppColors.statCardTeal,
      },
      {
        'title': 'Créditos Finalizados',
        'value': homeData?.creditosActFin.first.creditos_finalizados ?? '0',
        'icon': Icons.check_circle_rounded,
        'color': AppColors.statCardSuccess,
      },
      {
        'title': 'Créditos Individuales',
        'value':
            (homeData?.gruposIndGrupos.isNotEmpty ?? false)
                ? homeData!.gruposIndGrupos.first.creditos_individuales ?? '0'
                : '0',
        'icon': Icons.person,
        'color': AppColors.warning,
      },
      {
        'title': 'Créditos Grupales',
        'value':
            (homeData?.gruposIndGrupos.isNotEmpty ?? false)
                ? homeData!.gruposIndGrupos.first.creditos_grupales ?? '0'
                : '0',
        'icon': Icons.group,
        'color': AppColors.statCardTeal,
      },
    ];

    if (isSmallScreen) {
      // Layout de Carrusel para Móvil (sin cambios)
      return SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: cardData.length,
          itemBuilder: (context, index) {
            final data = cardData[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 140,
                child: _buildStatCardConsistentHeight(
                  title: data['title'] as String,
                  value: data['value'] as String,
                  icon: data['icon'] as IconData,
                  color: data['color'] as Color,
                  isSmallScreen: isSmallScreen,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Layout de Grid para Escritorio (sin cambios)
      return LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          const double spacing = 8.0;
          final double itemWidth =
              (width - (spacing * (crossAxisCount - 1))) / crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children:
                cardData.map((data) {
                  return SizedBox(
                    width: itemWidth,
                    child: _buildStatCardConsistentHeight(
                      title: data['title'] as String,
                      value: data['value'] as String,
                      icon: data['icon'] as IconData,
                      color: data['color'] as Color,
                      isSmallScreen: isSmallScreen,
                    ),
                  );
                }).toList(),
          );
        },
      );
    }
  }

  String formatearNumero(double numero) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(numero);
  }

  Widget _buildStatCardConsistentHeight({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: isSmallScreen ? 90 : 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: isSmallScreen ? 10 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // PARTE SUPERIOR: El monto
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // PARTE INFERIOR: Título e ícono
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: colors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: isSmallScreen ? 24 : 28),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Modelos de datos (Sin cambios)
class HomeData {
  final List<CreditosActFin> creditosActFin;
  final List<GruposIndGrupos> gruposIndGrupos;
  final List<SumaPagos> sumaPagos;

  HomeData({
    required this.creditosActFin,
    required this.gruposIndGrupos,
    required this.sumaPagos,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      creditosActFin:
          (json['creditosActFin'] as List)
              .map((e) => CreditosActFin.fromJson(e))
              .toList(),
      gruposIndGrupos:
          (json['gruposIndGrupos'] as List)
              .map((e) => GruposIndGrupos.fromJson(e))
              .toList(),
      sumaPagos:
          (json['sumaPagos'] as List)
              .map((e) => SumaPagos.fromJson(e))
              .toList(),
    );
  }
}

class CreditosActFin {
  final String? creditos_activos;
  final String? creditos_finalizados;

  CreditosActFin({
    required this.creditos_activos,
    required this.creditos_finalizados,
  });

  factory CreditosActFin.fromJson(Map<String, dynamic> json) {
    return CreditosActFin(
      creditos_activos: json['creditos_activos']?.toString() ?? '0',
      creditos_finalizados: json['creditos_finalizados']?.toString() ?? '0',
    );
  }
}

class GruposIndGrupos {
  final int total_grupos;
  final String? creditos_individuales;
  final String? creditos_grupales;
  final String? grupos_activos;
  final String? grupos_finalizados;

  GruposIndGrupos({
    required this.total_grupos,
    required this.creditos_individuales,
    required this.creditos_grupales,
    required this.grupos_activos,
    required this.grupos_finalizados,
  });

  factory GruposIndGrupos.fromJson(Map<String, dynamic> json) {
    return GruposIndGrupos(
      total_grupos: json['total_grupos'] ?? 0,
      creditos_individuales: json['creditos_individuales']?.toString() ?? '0',
      creditos_grupales: json['creditos_grupales']?.toString() ?? '0',
      grupos_activos: json['grupos_activos']?.toString() ?? '0',
      grupos_finalizados: json['grupos_finalizados']?.toString() ?? '0',
    );
  }
}

class SumaPagos {
  final String? sumaDepositos;

  SumaPagos({required this.sumaDepositos});

  factory SumaPagos.fromJson(Map<String, dynamic> json) {
    return SumaPagos(sumaDepositos: json['sumaDepositos']?.toString() ?? '0');
  }
}
