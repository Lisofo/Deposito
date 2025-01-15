// To parse this JSON data, do
//
//     final codigoBarras = codigoBarrasFromMap(jsonString);

import 'dart:convert';

List<CodigoBarras> codigoBarrasFromMap(String str) => List<CodigoBarras>.from(json.decode(str).map((x) => CodigoBarras.fromJson(x)));

String codigoBarrasToMap(List<CodigoBarras> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class CodigoBarras {
  late int codBarraId;
  late int itemId;
  late String codigoBarra;
  late dynamic fechabaja;

  CodigoBarras({
    required this.codBarraId,
    required this.itemId,
    required this.codigoBarra,
    required this.fechabaja,
  });

  factory CodigoBarras.fromJson(Map<String, dynamic> json) => CodigoBarras(
    codBarraId: json["CodBarraId"] as int? ?? 0,
    itemId: json["ItemId"] as int? ?? 0,
    codigoBarra: json["CodigoBarra"] as String? ?? '',
    fechabaja: json["fechabaja"],
  );

  Map<String, dynamic> toMap() => {
    "CodBarraId": codBarraId,
    "ItemId": itemId,
    "CodigoBarra": codigoBarra,
  };

  CodigoBarras.empty() {
    codBarraId = 0;
    itemId = 0;
    codigoBarra = '';
    fechabaja = null;
  }
}
