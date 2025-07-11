// To parse this JSON data, do
//
//     final formaEnvio = formaEnvioFromJson(jsonString);

import 'dart:convert';

List<FormaEnvio> formaEnvioFromJson(String str) => List<FormaEnvio>.from(json.decode(str).map((x) => FormaEnvio.fromJson(x)));

String formaEnvioToJson(List<FormaEnvio> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class FormaEnvio {
  late int formaEnvioId;
  late String codFormaEnvio;
  late String? descripcion;
  late bool? agencia;
  late bool? tr;
  late bool? envio;
  late DateTime? fechabaja;

  FormaEnvio({
    required this.formaEnvioId,
    required this.codFormaEnvio,
    required this.descripcion,
    required this.agencia,
    required this.tr,
    required this.envio,
    required this.fechabaja,
  });

  factory FormaEnvio.fromJson(Map<String, dynamic> json) => FormaEnvio(
    formaEnvioId: json["formaEnvioId"]as int? ?? 0,
    codFormaEnvio: json["codFormaEnvio"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    agencia: json["agencia"],
    tr: json["tr"],
    envio: json["envio"],
    fechabaja: json["fechabaja"] != null ? DateTime.parse(json["fechabaja"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "formaEnvioId": formaEnvioId,
    "codFormaEnvio": codFormaEnvio,
    "descripcion": descripcion,
    "agencia": agencia,
    "tr": tr,
    "envio": envio,
    "fechabaja": fechabaja,
  };

  FormaEnvio.empty() {
    formaEnvioId = 0;
    codFormaEnvio = '';
    descripcion = '';
    agencia = null;
    tr = null;
    envio = null;
    fechabaja = DateTime.now();
  }

  @override
  String toString() {
    return descripcion.toString();
  }
}
