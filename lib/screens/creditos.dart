import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora_app/screens/login.dart';
import 'package:finora_app/ip.dart'; // Asegúrate de tener esta configuración

class SeguimientoScreenMobile extends StatefulWidget {
  final String username;
  final String tipoUsuario;

  const SeguimientoScreenMobile({
    required this.username,
    required this.tipoUsuario,
  });

  @override
  _SeguimientoScreenMobileState createState() =>
      _SeguimientoScreenMobileState();
}

class _SeguimientoScreenMobileState extends State<SeguimientoScreenMobile> {
  List<Credito> listaCreditos = [];
  bool isLoading = false;
  bool errorDeConexion = false;
  bool noCreditsFound = false;
  String _searchQuery = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    obtenerCreditos();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> obtenerCreditos() async {
    setState(() {
      isLoading = true;
      errorDeConexion = false;
      noCreditsFound = false;
    });

    bool dialogShown = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenauth') ?? '';

      final response = await http
          .get(
            Uri.parse('http://$baseUrl/api/v1/creditos'),
            headers: {'tokenauth': token, 'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          listaCreditos = data.map((item) => Credito.fromJson(item)).toList();
          listaCreditos.sort((a, b) => b.fCreacion.compareTo(a.fCreacion));
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _handleTokenExpiration();
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        setState(() {
          listaCreditos = [];
          isLoading = false;
          noCreditsFound = true;
        });
      } else {
        _showErrorDialog('Error al cargar los créditos');
      }
    } on SocketException {
      _showErrorDialog('Error de conexión. Verifica tu red.');
    } on TimeoutException {
      _showErrorDialog('Tiempo de espera agotado');
    } catch (e) {
      _showErrorDialog('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _handleTokenExpiration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tokenauth');

    if (mounted) {
      _showErrorDialog(
        'Sesión expirada. Por favor inicia sesión nuevamente.',
        onClose: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        },
      );
    }
  }

  void _showErrorDialog(String message, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onClose?.call();
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _searchCreditos(String query) async {
    if (query.isEmpty) {
      obtenerCreditos();
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenauth') ?? '';

      final response = await http
          .get(
            Uri.parse('http://$baseUrl/api/v1/creditos/$query'),
            headers: {'tokenauth': token},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          listaCreditos = data.map((item) => Credito.fromJson(item)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      _showErrorDialog('Error en la búsqueda: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créditos Activos'),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: _showSearchDialog),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        //onPressed: _showAddCreditoDialog,
        onPressed: () {},
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) return _buildLoading();
    if (errorDeConexion) return _buildErrorState();
    if (noCreditsFound || listaCreditos.isEmpty) return _buildEmptyState();
    return _buildCreditosList();
  }

  Widget _buildCreditosList() {
    return RefreshIndicator(
      onRefresh: obtenerCreditos,
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: listaCreditos.length,
        itemBuilder: (context, index) {
          final credito = listaCreditos[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              // onTap: () => _showCreditoDetails(credito),
              onTap: () {},
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            credito.nombreGrupo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildStatusChip(credito.estado),
                      ],
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow('Monto:', credito.montoTotal),
                    _buildInfoRow('Desembolsado:', credito.montoDesembolsado),
                    _buildInfoRow('Cuota:', credito.pagoCuota),
                    _buildInfoRowString(
                      'Próximo pago:',
                      credito.fechasIniciofin,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Para valores double
  Widget _buildInfoRow(String label, double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label ', style: TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            '\$${formatearNumero(value)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Para valores String
  Widget _buildInfoRowString(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label ', style: TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String formatearNumero(double numero) {
    return NumberFormat("#,##0.00", "es_MX").format(numero);
  }

  Widget _buildStatusChip(String estado) {
    final colors = {
      'Activo': Colors.green,
      'Finalizado': Colors.red,
      'default': Colors.grey,
    };

    final color = colors[estado] ?? colors['default']!;

    return Chip(
      label: Text(estado),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontSize: 12),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildLoading() => Center(child: CircularProgressIndicator());

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.credit_card_off, size: 60, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'No se encontraron créditos',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    ),
  );

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 60, color: Colors.red),
        SizedBox(height: 16),
        Text(
          'Error de conexión',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
        SizedBox(height: 8),
        ElevatedButton(onPressed: obtenerCreditos, child: Text('Reintentar')),
      ],
    ),
  );

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Buscar créditos'),
            content: TextField(
              decoration: InputDecoration(
                hintText: 'Folio o nombre...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _searchQuery = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _searchCreditos(_searchQuery);
                },
                child: Text('Buscar'),
              ),
            ],
          ),
    );
  }

  /*  void _showCreditoDetails(Credito credito) {
    showDialog(
      context: context,
      builder: (context) => InfoCreditoDialog(folio: credito.folio),
    );
  }

  void _showAddCreditoDialog() {
    showDialog(
      context: context,
      builder: (context) => nCreditoDialog(
        onCreditoAgregado: obtenerCreditos,
      ),
    );
  } */
}

class Credito {
  final String idCredito;
  final String nombreGrupo;
  final int plazo;
  final String tipoPlazo;
  final String tipo;
  final double interes;
  final double montoDesembolsado;
  final String folio;
  final String diaPago;
  final double garantia;
  final double pagoCuota;
  final double interesGlobal;
  final double montoTotal;
  final double ti_mensual;
  final double interesTotal;
  final double montoMasInteres;
  final String numPago;
  final String fechasIniciofin;
  final DateTime fCreacion;
  final String estado;
  final EstadoCredito estadoCredito;

  Credito({
    required this.idCredito,
    required this.nombreGrupo,
    required this.plazo,
    required this.tipoPlazo,
    required this.tipo,
    required this.interes,
    required this.montoDesembolsado,
    required this.folio,
    required this.diaPago,
    required this.garantia,
    required this.pagoCuota,
    required this.interesGlobal,
    required this.montoTotal,
    required this.ti_mensual,
    required this.interesTotal,
    required this.montoMasInteres,
    required this.numPago,
    required this.fechasIniciofin,
    required this.estadoCredito,
    required this.estado,
    required this.fCreacion,
  });

  factory Credito.fromJson(Map<String, dynamic> json) {
    return Credito(
      idCredito: json['idcredito'],
      nombreGrupo: json['nombreGrupo'],
      plazo: json['plazo'] is String ? int.parse(json['plazo']) : json['plazo'],
      tipoPlazo: json['tipoPlazo'],
      tipo: json['tipo'],
      interes: json['interesGlobal'].toDouble(),
      montoDesembolsado: json['montoDesembolsado'].toDouble(),
      folio: json['folio'],
      diaPago: json['diaPago'],
      garantia: double.parse(json['garantia'].replaceAll('%', '')),
      pagoCuota: json['pagoCuota'].toDouble(),
      interesGlobal: json['interesGlobal'].toDouble(),
      ti_mensual: json['ti_mensual'].toDouble(),
      montoTotal: json['montoTotal'].toDouble(),
      interesTotal: json['interesTotal'].toDouble(),
      montoMasInteres: json['montoMasInteres'].toDouble(),
      numPago: json['numPago'],
      fechasIniciofin: json['fechasIniciofin'],
      estado: json['estado'],
      estadoCredito: EstadoCredito.fromJson(json['estado_credito']),
      fCreacion: DateTime.parse(json['fCreacion']),
    );
  }
}

class EstadoCredito {
  final double montoTotal;
  final double moratorios;
  final int semanasDeRetraso;
  final int diferenciaEnDias;
  final String mensaje;
  final String estado;

  EstadoCredito({
    required this.montoTotal,
    required this.moratorios,
    required this.semanasDeRetraso,
    required this.diferenciaEnDias,
    required this.mensaje,
    required this.estado,
  });

  factory EstadoCredito.fromJson(Map<String, dynamic> json) {
    return EstadoCredito(
      montoTotal: (json['montoTotal'] as num).toDouble(), // Convertir a double
      moratorios: (json['moratorios'] as num).toDouble(), // Convertir a double
      semanasDeRetraso: json['semanasDeRetraso'],
      diferenciaEnDias: json['diferenciaEnDias'],
      mensaje: json['mensaje'],
      estado:
          json['esatado'], // Nota: el JSON tiene un error de tipografía aquí ("esatado" en lugar de "estado").
    );
  }
}
