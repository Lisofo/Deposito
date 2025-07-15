// ubicacion_picking.dart
class UbicacionPicking {
  final String codUbicacion;
  final int cantidadPickeada;
  final int existenciaActual;

  UbicacionPicking({
    required this.codUbicacion,
    required this.cantidadPickeada,
    required this.existenciaActual,
  });

  factory UbicacionPicking.empty() {
    return UbicacionPicking(
      codUbicacion: '',
      cantidadPickeada: 0,
      existenciaActual: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codUbicacion': codUbicacion,
      'cantidadPickeada': cantidadPickeada,
      'existenciaActual': existenciaActual,
    };
  }

  factory UbicacionPicking.fromMap(Map<String, dynamic> map) {
    return UbicacionPicking(
      codUbicacion: map['codUbicacion'] ?? '',
      cantidadPickeada: map['cantidadPickeada'] ?? 0,
      existenciaActual: map['existenciaActual'] ?? 0,
    );
  }
}