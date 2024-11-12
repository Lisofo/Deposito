// To parse this JSON data, do
//
//     final almacen = almacenFromMap(jsonString);

import 'dart:convert';

List<Almacen> almacenFromMap(String str) => List<Almacen>.from(json.decode(str).map((x) => Almacen.fromJson(x)));

String almacenToMap(List<Almacen> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Almacen {
  late int almacenId;
  late String codAlmacen;
  late String descripcion;
  late String direccion;
  late String telefono;

  Almacen({
    required this.almacenId,
    required this.codAlmacen,
    required this.descripcion,
    required this.direccion,
    required this.telefono,
  });

  factory Almacen.fromJson(Map<String, dynamic> json) => Almacen(
    almacenId: json["almacenId"] as int? ?? 0,
    codAlmacen: json["codAlmacen"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    direccion: json["direccion"] as String? ?? '',
    telefono: json["telefono"] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    "almacenId": almacenId,
    "codAlmacen": codAlmacen,
    "descripcion": descripcion,
    "direccion": direccion,
    "telefono": telefono,
  };

  Almacen.empty() {
    almacenId = 0;
    codAlmacen = '';
    descripcion = '';
    direccion = '';
    telefono = '';
  }
}
