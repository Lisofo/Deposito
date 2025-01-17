// To parse this JSON data, do
//
//     final itemsPorUbicacion = itemsPorUbicacionFromJson(jsonString);

import 'dart:convert';

List<ItemsPorUbicacion> itemsPorUbicacionFromJson(String str) => List<ItemsPorUbicacion>.from(json.decode(str).map((x) => ItemsPorUbicacion.fromJson(x)));

String itemsPorUbicacionToJson(List<ItemsPorUbicacion> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ItemsPorUbicacion {
  late int itemAlmacenUbicacionId;
  late int itemId;
  late int almacenUbicacionId;
  late int existenciaActual;
  late int existenciaMaxima;
  late int existenciaMinima;
  late int almacenId;
  late int capacidad;
  late int orden;
  late dynamic fechaBaja;
  late String codUbicacion;
  late String descripcion;

  ItemsPorUbicacion({
    required this.itemAlmacenUbicacionId,
    required this.itemId,
    required this.almacenUbicacionId,
    required this.existenciaActual,
    required this.existenciaMaxima,
    required this.existenciaMinima,
    required this.fechaBaja,
    required this.almacenId,
    required this.codUbicacion,
    required this.descripcion,
    required this.capacidad,
    required this.orden,
  });

  factory ItemsPorUbicacion.fromJson(Map<String, dynamic> json) => ItemsPorUbicacion(
    itemAlmacenUbicacionId: json["itemAlmacenUbicacionId"] as int? ?? 0,
    itemId: json["itemId"] as int? ?? 0,
    almacenUbicacionId: json["almacenUbicacionId"] as int? ?? 0,
    existenciaActual: json["existenciaActual"] as int? ?? 0,
    existenciaMaxima: json["existenciaMaxima"] as int? ?? 0,
    existenciaMinima: json["existenciaMinima"] as int? ?? 0,
    almacenId: json["almacenId"] as int? ?? 0,
    capacidad: json["capacidad"] as int? ?? 0,
    orden: json["orden"] as int? ?? 0,
    fechaBaja: json["fechaBaja"],
    codUbicacion: json["codUbicacion"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    "itemAlmacenUbicacionId": itemAlmacenUbicacionId,
    "itemId": itemId,
    "almacenUbicacionId": almacenUbicacionId,
    "existenciaActual": existenciaActual,
    "existenciaMaxima": existenciaMaxima,
    "existenciaMinima": existenciaMinima,
    "fechaBaja": fechaBaja,
    "almacenId": almacenId,
    "codUbicacion": codUbicacion,
    "descripcion": descripcion,
    "capacidad": capacidad,
    "orden": orden,
  };

  ItemsPorUbicacion.empty() {
    itemAlmacenUbicacionId = 0;
    itemId = 0;
    almacenUbicacionId = 0;
    existenciaActual = 0;
    existenciaMaxima = 0;
    existenciaMinima = 0;
    almacenId = 0;
    capacidad = 0;
    orden = 0;
    fechaBaja = null;
    codUbicacion = '';
    descripcion = '';
  }
}
