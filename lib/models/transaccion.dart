// To parse this JSON data, do
//
//     final transaccion = transaccionFromJson(jsonString);

import 'dart:convert';

List<Transaccion> transaccionFromJson(String str) => List<Transaccion>.from(json.decode(str).map((x) => Transaccion.fromJson(x)));

String transaccionToJson(List<Transaccion> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Transaccion {
  late int transaccionId;
  late String codTransaccion;
  late String descripcion;

  Transaccion({
    required this.transaccionId,
    required this.codTransaccion,
    required this.descripcion,
  });

  factory Transaccion.fromJson(Map<String, dynamic> json) => Transaccion(
    transaccionId: json["transaccionId"] as int? ?? 0,
    codTransaccion: json["codTransaccion"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    "transaccionId": transaccionId,
    "codTransaccion": codTransaccion,
    "descripcion": descripcion,
  };

  Transaccion.empty() {
    transaccionId = 0;
    codTransaccion = '';
    descripcion = '';
  }
}