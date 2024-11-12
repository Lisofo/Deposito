// To parse this JSON data, do
//
//     final moneda = monedaFromJson(jsonString);

import 'dart:convert';

List<Moneda> monedaFromJson(String str) => List<Moneda>.from(json.decode(str).map((x) => Moneda.fromJson(x)));

String monedaToJson(List<Moneda> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Moneda {
  late int monedaId;
  late String codMoneda;
  late String descripcion;
  late String signo;

  Moneda({
    required this.monedaId,
    required this.codMoneda,
    required this.descripcion,
    required this.signo,
  });

  factory Moneda.fromJson(Map<String, dynamic> json) => Moneda(
    monedaId: json["monedaId"] as int? ?? 0,
    codMoneda: json["codMoneda"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    signo: json["signo"] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    "monedaId": monedaId,
    "codMoneda": codMoneda,
    "descripcion": descripcion,
    "signo": signo,
  };

  Moneda.empty() {
    monedaId = 0;
    codMoneda = '';
    descripcion = '';
    signo = '';
  }
}