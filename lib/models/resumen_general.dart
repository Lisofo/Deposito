class ResumenGeneral {
  late int usuarioId;
  late int conteo;
  late String nombre;
  late String apelldio;

  ResumenGeneral({
    required this.conteo,
    required this.usuarioId,
    required this.nombre,
    required this.apelldio,
  });

  factory ResumenGeneral.fromJson(Map<String, dynamic> json) => ResumenGeneral(
    conteo: json['conteos'] as int? ?? 0,
    usuarioId: json['usuarioId'] as int? ?? 0,
    nombre: json['nombre'] as String? ?? '',
    apelldio: json['apellido'] as String? ?? '',
  );

  ResumenGeneral.empty() {
    usuarioId = 0;
    conteo = 0;
    nombre = '';
    apelldio = '';
  }
}