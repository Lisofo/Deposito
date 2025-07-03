// To parse this JSON data, do
//
//     final tipoBulto = tipoBultoFromJson(jsonString);

import 'dart:convert';

List<TipoBulto> tipoBultoFromJson(String str) => List<TipoBulto>.from(json.decode(str).map((x) => TipoBulto.fromJson(x)));

String tipoBultoToJson(List<TipoBulto> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoBulto {
  late int tipoBultoId;
  late String codTipoBulto;
  late String descripcion;
  late String icon;

  TipoBulto({
    required this.tipoBultoId,
    required this.codTipoBulto,
    required this.descripcion,
    required this.icon,
  });

  factory TipoBulto.fromJson(Map<String, dynamic> json) => TipoBulto(
    tipoBultoId: json["tipoBultoId"] as int? ?? 0,
    codTipoBulto: json["codTipoBulto"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    icon: json["icon"] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    "tipoBultoId": tipoBultoId,
    "codTipoBulto": codTipoBulto,
    "descripcion": descripcion,
  };

  TipoBulto.empty() {
    tipoBultoId = 0;
    codTipoBulto = '';
    descripcion = '';
    icon = '';
  }
}
