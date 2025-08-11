// models/image_data.dart
class ImageData {
  final String tipoImagen;
  final String rutaImagen;

  ImageData({
    required this.tipoImagen,
    required this.rutaImagen,
  });


  /// Convierte un objeto ImageData a un Map (para ser guardado en formato JSON).
  Map<String, dynamic> toJson() => {
    'tipoImagen': tipoImagen,
    'rutaImagen': rutaImagen,
  };

  /// Crea un objeto ImageData a partir de un Map (leído desde formato JSON).
  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      tipoImagen: json['tipoImagen'],
      rutaImagen: json['rutaImagen'],
    );
  }
}