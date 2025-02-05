// To parse this JSON data, do
//
//     final conteo = conteoFromJson(jsonString);

import 'dart:convert';

List<Conteo> conteoFromJson(String str) => List<Conteo>.from(json.decode(str).map((x) => Conteo.fromJson(x)));

String conteoToJson(List<Conteo> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Conteo {
  late int itemConteoId;
  late DateTime fechaConteo;
  late int usuarioId;
  late int almacenId;
  late int almacenUbicacionId;
  late int itemId;
  late String codItem;
  late String descripcion;
  late int stock;
  late int conteo;

  Conteo({
    required this.itemConteoId,
    required this.fechaConteo,
    required this.usuarioId,
    required this.almacenId,
    required this.almacenUbicacionId,
    required this.itemId,
    required this.codItem,
    required this.descripcion,
    required this.stock,
    required this.conteo,
  });

  factory Conteo.fromJson(Map<String, dynamic> json) => Conteo(
    itemConteoId: json["itemConteoId"] as int? ?? 0,
    fechaConteo: DateTime.parse(json["fechaConteo"]),
    usuarioId: json["usuarioId"] as int? ?? 0,
    almacenId: json["almacenId"] as int? ?? 0,
    almacenUbicacionId: json["almacenUbicacionId"] as int? ?? 0,
    itemId: json["itemId"] as int? ?? 0,
    codItem: json["codItem"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    stock: json["stock"] as int? ?? 0,
    conteo: json["conteo"] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "itemConteoId": itemConteoId,
    "fechaConteo": fechaConteo.toIso8601String(),
    "usuarioId": usuarioId,
    "almacenId": almacenId,
    "almacenUbicacionId": almacenUbicacionId,
    "itemId": itemId,
    "codItem": codItem,
    "descripcion": descripcion,
    "stock": stock,
    "conteo": conteo,
  };

  Conteo.empty() {
    itemConteoId = 0;
    fechaConteo = DateTime.now();
    usuarioId = 0;
    almacenId = 0;
    almacenUbicacionId = 0;
    itemId = 0;
    codItem = '';
    descripcion = '';
    stock = 0;
    conteo = 0;
  }
}
