// To parse this JSON data, do
//
//     final ubicacionAlmacen = ubicacionAlmacenFromJson(jsonString);

import 'dart:convert';

List<UbicacionAlmacen> ubicacionAlmacenFromJson(String str) => List<UbicacionAlmacen>.from(json.decode(str).map((x) => UbicacionAlmacen.fromJson(x)));

String ubicacionAlmacenToJson(List<UbicacionAlmacen> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class UbicacionAlmacen {
  late int almacenUbicacionId;
  late int almacenId;
  late String codUbicacion;
  late String descripcion;
  late int capacidad;
  late int orden;

  UbicacionAlmacen({
    required this.almacenUbicacionId,
    required this.almacenId,
    required this.codUbicacion,
    required this.descripcion,
    required this.capacidad,
    required this.orden,
  });

  factory UbicacionAlmacen.fromJson(Map<String, dynamic> json) => UbicacionAlmacen(
    almacenUbicacionId: json["almacenUbicacionId"] as int? ?? 0,
    almacenId: json["almacenId"] as int? ?? 0,
    codUbicacion: json["codUbicacion"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    capacidad: json["capacidad"] as int? ?? 0,
    orden: json["orden"] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "almacenUbicacionId": almacenUbicacionId,
    "almacenId": almacenId,
    "codUbicacion": codUbicacion,
    "descripcion": descripcion,
    "capacidad": capacidad,
    "orden": orden,
  };

  UbicacionAlmacen.empty() {
    almacenUbicacionId = 0;
    almacenId = 0;
    codUbicacion = '';
    descripcion = '';
    capacidad = 0;
    orden = 0;
  }

  @override
  String toString() {
    return '$codUbicacion $descripcion';
  }
}
