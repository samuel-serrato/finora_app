import 'dart:convert';
import 'package:finora_app/ip.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  Future<void> _fetchHomeData() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    final Uri url = Uri.parse('http://$baseUrl/api/v1/home');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          homeData = HomeData.fromJson(responseData);
          isLoading = false;
          _isRefreshing = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Error del servidor: ${response.statusCode}';
          isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error de conexión';
        isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF7F8FA),
      body: RefreshIndicator(
        onRefresh: _fetchHomeData,
        child: _buildBody(isSmallScreen),
      ),
    );
  }

  Widget _buildBody(bool isSmallScreen) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12.0 : 16.0,
          vertical: 12.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            welcomeCard(),
            const SizedBox(height: 16),
            _buildSummaryHeader(),
            const SizedBox(height: 12),
            Expanded(child: statCardsList(isSmallScreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Resumen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDarkMode ? Colors.blueGrey[800]! : Color(0xFF6A88F7),
              isDarkMode ? Colors.blueGrey[900]! : Color(0xFF5162F6),
            ],
          ),
        ),
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.waving_hand_rounded, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Hola, ${widget.username}!",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Bienvenido a tu panel de control",
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            SizedBox(height: 4),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchHomeData,
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Adaptar la cuadricula según el tamaño de la pantalla
    final crossAxisCount = isSmallScreen ? 2 : 3;
    final childAspectRatio = isSmallScreen ? 1.0 : 1.2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: isSmallScreen ? 8 : 12,
      mainAxisSpacing: isSmallScreen ? 8 : 12,
      children: [
        _buildStatCard(
          title: 'Créditos Activos',
          value: homeData?.creditosActFin.first.creditos_activos ?? '0',
          icon: Icons.group_work_rounded,
          color: const Color(0xFF5162F6),
          isSmallScreen: isSmallScreen,
        ),
        _buildStatCard(
          title: 'Créditos Finalizados',
          value: homeData?.creditosActFin.first.creditos_finalizados ?? '0',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF6BC950),
          isSmallScreen: isSmallScreen,
        ),
        _buildStatCard(
          title: 'Grupos Individuales',
          value: homeData?.gruposIndGrupos.first.grupos_individuales ?? '0',
          icon: Icons.person,
          color: const Color(0xFF4ECDC4),
          isSmallScreen: isSmallScreen,
        ),
        _buildStatCard(
          title: 'Grupos Grupales',
          value: homeData?.gruposIndGrupos.first.grupos_grupales ?? '0',
          icon: Icons.group,
          color: const Color(0xFF4ECDC4),
          isSmallScreen: isSmallScreen,
        ),
        _buildStatCard(
          title: 'Acumulado Semanal',
          value:
              '\$${formatearNumero(double.tryParse(homeData?.sumaPagos.first.sumaDepositos ?? '0') ?? 0.0)}',
          icon: Icons.payments,
          color: const Color(0xFFFF6B6B),
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  String formatearNumero(double numero) {
    final formatter = NumberFormat("#,##0.00", "en_US"); // Formato español
    return formatter.format(numero);
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
        ),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: isSmallScreen ? 24 : 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
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
  final String? grupos_individuales;
  final String? grupos_grupales;

  GruposIndGrupos({
    required this.grupos_individuales,
    required this.grupos_grupales,
  });

  factory GruposIndGrupos.fromJson(Map<String, dynamic> json) {
    return GruposIndGrupos(
      grupos_individuales: json['grupos_individuales']?.toString() ?? '0',
      grupos_grupales: json['grupos_grupales']?.toString() ?? '0',
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
