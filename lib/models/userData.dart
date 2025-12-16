// models/usuario_completo.dart

import 'package:finora_app/models/image_data.dart';
import 'package:finora_app/models/licencia.dart';

class UserData {
  final String idusuarios;
  final String usuario;
  final String tipoUsuario;
  final String nombreCompleto;
  final String email;
  final List<String> roles;
  final String dbName;
  final String nombreNegocio;
  final List<ImageData> imagenes;
  final String idnegocio;
  final double redondeo;
  final List<Licencia> licencia;

  // Getter para acceder fácilmente a la primera licencia (la más común)
  Licencia? get licenciaActiva => licencia.isNotEmpty ? licencia.first : null;

  UserData({
    required this.idusuarios,
    required this.usuario,
    required this.tipoUsuario,
    required this.nombreCompleto,
    required this.email,
    required this.roles,
    required this.dbName,
    required this.nombreNegocio,
    required this.imagenes,
    required this.idnegocio,
    required this.redondeo,
    required this.licencia,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
  // 1. Procesar imágenes (esto estaba bien)
  var imagenesList = json['imagenes'] as List? ?? [];
  List<ImageData> imagenesData = imagenesList.map((i) => ImageData.fromJson(i)).toList();

  // 2. CORRECCIÓN EN LICENCIA
  List<Licencia> licenciaData = [];
  
  if (json['licencia'] is List) {
    // Si la API cambia y envía una lista, esto funcionará
    licenciaData = (json['licencia'] as List).map((i) => Licencia.fromJson(i)).toList();
  } else if (json['licencia'] is Map) {
    // Si la API envía un objeto (tu caso actual), lo convertimos en una lista de 1 elemento
    licenciaData = [Licencia.fromJson(json['licencia'])];
  }

  return UserData(
    idusuarios: json['idusuarios'] ?? '',
    usuario: json['usuario'] ?? '',
    tipoUsuario: json['tipoUsuario'] ?? '',
    nombreCompleto: json['nombreCompleto'] ?? '',
    email: json['email'] ?? '',
    roles: List<String>.from(json['roles'] ?? []),
    dbName: json['dbName'] ?? '',
    nombreNegocio: json['nombreNegocio'] ?? '',
    imagenes: imagenesData,
    idnegocio: json['idnegocio'] ?? '',
    redondeo: (json['redondeo'] as num?)?.toDouble() ?? 0.0,
    licencia: licenciaData, // Pasamos la lista corregida
  );
}

  Map<String, dynamic> toJson() {
    return {
      'idusuarios': idusuarios,
      'usuario': usuario,
      'tipoUsuario': tipoUsuario,
      'nombreCompleto': nombreCompleto,
      'email': email,
      'roles': roles,
      'dbName': dbName,
      'nombreNegocio': nombreNegocio,
      'imagenes': imagenes.map((img) => img.toJson()).toList(),
      'idnegocio': idnegocio,
      'redondeo': redondeo,
      'licencia': licencia.map((l) => l.toJson()).toList(),
    };
  }
}