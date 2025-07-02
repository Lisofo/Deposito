// To parse this JSON data, do
//
//     final modoEnvio = modoEnvioFromJson(jsonString);

import 'dart:convert';

List<ModoEnvio> modoEnvioFromJson(String str) => List<ModoEnvio>.from(json.decode(str).map((x) => ModoEnvio.fromJson(x)));

String modoEnvioToJson(List<ModoEnvio> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ModoEnvio {
  late int modoEnvioId;
  late String codModoEnvio;
  late String descripcion;

  ModoEnvio({
    required this.modoEnvioId,
    required this.codModoEnvio,
    required this.descripcion,
  });

  factory ModoEnvio.fromJson(Map<String, dynamic> json) => ModoEnvio(
    modoEnvioId: json["modoEnvioId"] as int? ?? 0,
    codModoEnvio: json["codModoEnvio"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    "modoEnvioId": modoEnvioId,
    "codModoEnvio": codModoEnvio,
    "descripcion": descripcion,
  };

  ModoEnvio.empty() {
    modoEnvioId = 0;
    codModoEnvio = '';
    descripcion = '';
  }
}
