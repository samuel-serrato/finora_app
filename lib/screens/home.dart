import 'dart:async';
import 'dart:convert';
import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/ip.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/screens/login.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_logger.dart';


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

class _HomeScreenState extends State<HomeScreen> {
  HomeData? homeData;
  bool isLoading = true;
  String errorMessage = '';
  bool _isRefreshing = false;
  final ApiService _apiService = ApiService();

  final AppColors colors = AppColors();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.setContext(context);
      _fetchHomeData();
    });
  }

   Future<void> _fetchHomeData() async {
    if(!mounted) return;
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
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: RefreshIndicator(
        onRefresh: _fetchHomeData,
        child: _buildBody(isSmallScreen),
      ),
    );
  }

  // CAMBIO 1: Envuelto en SingleChildScrollView para evitar overflow.
  Widget _buildBody(bool isSmallScreen) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12.0 : 24.0, // Más padding en desktop
            vertical: 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              welcomeCard(),
              const SizedBox(height: 24),
              _buildSummaryHeader(),
              const SizedBox(height: 16),
              // CAMBIO 2: Se quitó el Expanded. El GridView ahora tomará su tamaño natural.
              statCardsList(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Resumen',
          style: TextStyle(
            fontSize: 20, // Un poco más grande
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: colors.homeWelcomeGradient,
        ),
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.waving_hand_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Hola, ${widget.username}!",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Bienvenido a tu panel de control",
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now()),
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statCardsList(bool isSmallScreen) {
    if (isLoading && !_isRefreshing) {
      // Un poco de padding para que el loader no esté pegado al borde
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
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

    // Usaremos LayoutBuilder para una mejor responsividad
      // Usamos LayoutBuilder para tomar decisiones basadas en el ancho real
  return LayoutBuilder(
    builder: (context, constraints) {
      // Definimos nuestros breakpoints y configuraciones
      final double width = constraints.maxWidth;
      int crossAxisCount;
      double childAspectRatio;

      if (width < 700) {
        // --- BREAKPOINT 1: MÓVIL ---
        // Pantallas pequeñas (móviles en vertical)
        crossAxisCount = 2;
        childAspectRatio = 1.0; // Tarjetas casi cuadradas, se ve bien
      } else if (width < 1100) {
        // --- BREAKPOINT 2: TABLET / LAPTOP PEQUEÑA ---
        // Este es el que resuelve tu problema principal.
        // Mantiene 3 columnas pero con una proporción que las hace más anchas.
        crossAxisCount = 3;
        childAspectRatio = 1.25; // Hacemos las tarjetas más anchas que altas
      } else {
        // --- BREAKPOINT 3: DESKTOP GRANDE ---
        // Aprovechamos todo el espacio para poner las 5 tarjetas en una fila.
        crossAxisCount = 5;
        childAspectRatio = 1.1; // Ajustamos la proporción para 5 columnas
      }

      return GridView.count(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true, // Crucial para que funcione dentro de SingleChildScrollView
        physics: const NeverScrollableScrollPhysics(), // El scroll lo maneja el padre
        children: [
          _buildStatCard(
            title: 'Créditos Activos',
            value: homeData?.creditosActFin.first.creditos_activos ?? '0',
            icon: Icons.group_work_rounded,
            color: AppColors.statCardCreditos,
            isSmallScreen: isSmallScreen,
          ),
          _buildStatCard(
            title: 'Créditos Finalizados',
            value: homeData?.creditosActFin.first.creditos_finalizados ?? '0',
            icon: Icons.check_circle_rounded,
            color: AppColors.statCardSuccess,
            isSmallScreen: isSmallScreen,
          ),
          _buildStatCard(
            title: 'Créditos Individuales',
            value: (homeData?.gruposIndGrupos.isNotEmpty ?? false)
                ? homeData!.gruposIndGrupos.first.creditos_individuales ?? '0'
                : '0',
            icon: Icons.person,
            color: AppColors.statCardTeal,
            isSmallScreen: isSmallScreen,
          ),
          _buildStatCard(
            title: 'Créditos Grupales',
            value: (homeData?.gruposIndGrupos.isNotEmpty ?? false)
                ? homeData!.gruposIndGrupos.first.creditos_grupales ?? '0'
                : '0',
            icon: Icons.group,
            color: AppColors.statCardTeal,
            isSmallScreen: isSmallScreen,
          ),
          _buildStatCard(
            title: 'Acumulado Semanal',
            value:
                '\$${formatearNumero(double.tryParse(homeData?.sumaPagos.first.sumaDepositos ?? '0') ?? 0.0)}',
            icon: Icons.payments,
            color: AppColors.statCardPayments,
            isSmallScreen: isSmallScreen,
          ),
        ],
      );
    },
  );
}

  String formatearNumero(double numero) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(numero);
  }

  // CAMBIO 3: El contenido se ve mejor ahora que la tarjeta no se estira
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bordes más redondeados
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
        ),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Esto ahora se ve bien
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: isSmallScreen ? 28 : 32), // Iconos un poco más grandes
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// Modelos de datos
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
