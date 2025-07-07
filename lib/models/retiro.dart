// To parse this JSON data, do
//
//     final retiro = retiroFromJson(jsonString);

import 'dart:convert';

Retiro retiroFromJson(String str) => Retiro.fromJson(json.decode(str));

String retiroToJson(Retiro data) => json.encode(data.toJson());

class Retiro {
  late int retiroId;
  late DateTime? fecha;
  late int agenciaTrId;
  late String retiradoPor;
  late String comentario;
  late int usuarioId;

  Retiro({
    required this.retiroId,
    required this.fecha,
    required this.agenciaTrId,
    required this.retiradoPor,
    required this.comentario,
    required this.usuarioId,
  });

  factory Retiro.fromJson(Map<String, dynamic> json) => Retiro(
    retiroId: json["retiroId"] as int? ?? 0,
    fecha: json['fecha'] != null ? DateTime.parse(json["fecha"]) : null,
    agenciaTrId: json["agenciaTrId"] as int? ?? 0,
    retiradoPor: json["retiradoPor"] as String? ?? '',
    comentario: json["comentario"] as String? ?? '',
    usuarioId: json["usuarioId"] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "retiroId": retiroId,
    "fecha": fecha?.toIso8601String(),
    "agenciaTrId": agenciaTrId,
    "retiradoPor": retiradoPor,
    "comentario": comentario,
    "usuarioId": usuarioId,
  };

  Retiro.empty() {
    retiroId = 0;
    fecha = DateTime.now();
    agenciaTrId = 0;
    retiradoPor = '';
    comentario = '';
    usuarioId = 0;
  }
}
