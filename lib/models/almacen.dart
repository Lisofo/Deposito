// To parse this JSON data, do
//
//     final almacen = almacenFromMap(jsonString);

import 'dart:convert';

import 'package:flutter/material.dart';

List<Almacen> almacenFromMap(String str) => List<Almacen>.from(json.decode(str).map((x) => Almacen.fromJson(x)));

String almacenToMap(List<Almacen> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Almacen {
  late int almacenId;
  late String codAlmacen;
  late String descripcion;
  late String direccion;
  late String telefono;
  late int r;
  late int g;
  late int b;
  late bool isSelected;

  Almacen({
    required this.almacenId,
    required this.codAlmacen,
    required this.descripcion,
    required this.direccion,
    required this.telefono,
    required this.r,
    required this.g,
    required this.b,
    required this.isSelected,
  });

  factory Almacen.fromJson(Map<String, dynamic> json) => Almacen(
    almacenId: json["almacenId"] as int? ?? 0,
    codAlmacen: json["codAlmacen"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    direccion: json["direccion"] as String? ?? '',
    telefono: json["telefono"] as String? ?? '',
    r: json['R'] as int? ?? 0,
    g: json['G'] as int? ?? 0,
    b: json['B'] as int? ?? 0,
    isSelected: false
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
    r = 0;
    g = 0;
    b = 0;
    isSelected = false;
  }

  Color get color => Color.fromARGB(255, r, g, b);
}
