// To parse this JSON data, do
//
//     final entrega = entregaFromJson(jsonString);

import 'dart:convert';

Entrega entregaFromJson(String str) => Entrega.fromJson(json.decode(str));

String entregaToJson(Entrega data) => json.encode(data.toJson());

class Entrega {
  late int entregaId;
  late DateTime fechaDate;
  late int almacenIdOrigen;
  late int usuId;
  late String estado;
  late List<OrdenesPicking> ordenesPicking;
  late List pickIds;
  late int cantBultos;

  Entrega({
    required this.entregaId,
    required this.fechaDate,
    required this.almacenIdOrigen,
    required this.usuId,
    required this.estado,
    required this.ordenesPicking,
    required this.pickIds,
    required this.cantBultos,
  });

  factory Entrega.fromJson(Map<String, dynamic> json) => Entrega(
    entregaId: json["entregaId"] as int? ?? 0,
    fechaDate: DateTime.parse(json["fechaDate"]),
    almacenIdOrigen: json["almacenIdOrigen"] as int? ?? 0,
    usuId: json["usuId"] as int? ?? 0,
    estado: json["estado"] as String? ?? '',
    ordenesPicking: json["ordenesPicking"] == null ? [] : List<OrdenesPicking>.from(json["ordenesPicking"].map((x) => OrdenesPicking.fromJson(x))),
    pickIds: json['pickIds'] ?? [],
    cantBultos: json['cantBultos'] as int? ?? 0, 
  );

  Map<String, dynamic> toJson() => {
    "entregaId": entregaId,
    "fechaDate": fechaDate.toIso8601String(),
    "almacenIdOrigen": almacenIdOrigen,
    "usuId": usuId,
    "estado": estado,
    "ordenesPicking": List<dynamic>.from(ordenesPicking.map((x) => x.toJson())),
    "pickIds": pickIds,
    'cantBultos': cantBultos
  };

  Entrega.empty() {
    entregaId = 0;
    fechaDate = DateTime.now();
    almacenIdOrigen = 0;
    usuId = 0;
    estado = '';
    ordenesPicking = [];
    pickIds = [];
    cantBultos = 0;
  }
}

class OrdenesPicking {
  late int entregaCabezalId;
  late int pickId;
  late int entregaId;

  OrdenesPicking({
    required this.entregaCabezalId,
    required this.pickId,
    required this.entregaId,
  });

  factory OrdenesPicking.fromJson(Map<String, dynamic> json) => OrdenesPicking(
    entregaCabezalId: json["entregaCabezalId"] as int? ?? 0,
    pickId: json["pickId"] as int? ?? 0,
    entregaId: json["entregaId"] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "entregaCabezalId": entregaCabezalId,
    "pickId": pickId,
    "entregaId": entregaId,
  };

  OrdenesPicking.empty() {
    entregaCabezalId = 0;
    pickId = 0;
    entregaId = 0;
  }
}
