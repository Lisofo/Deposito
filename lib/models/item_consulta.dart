// To parse this JSON data, do
//
//     final itemConsulta = itemConsultaFromMap(jsonString);

import 'dart:convert';

List<ItemConsulta> itemConsultaFromMap(String str) => List<ItemConsulta>.from(json.decode(str).map((x) => ItemConsulta.fromJson(x)));

String itemConsultaToMap(List<ItemConsulta> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ItemConsulta {
  late String raiz;
  late String descripcion;
  late String modelos;
  late List<String> fotosUrl;
  late List<Variante> variantes;

  ItemConsulta({
    required this.raiz,
    required this.descripcion,
    required this.modelos,
    required this.fotosUrl,
    required this.variantes,
  });

  factory ItemConsulta.fromJson(Map<String, dynamic> json) => ItemConsulta(
    raiz: json["raiz"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    modelos: json["modelos"] as String? ?? '',
    fotosUrl: List<String>.from(json["fotosUrl"].map((x) => x)),
    variantes: List<Variante>.from(json["variantes"].map((x) => Variante.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "raiz": raiz,
    "descripcion": descripcion,
    "modelos": modelos,
    "fotosUrl": List<dynamic>.from(fotosUrl.map((x) => x)),
    "variantes": List<dynamic>.from(variantes.map((x) => x.toMap())),
  };

  ItemConsulta.empty() {
    raiz = '';
    descripcion = '';
    modelos = '';
    fotosUrl = [];
    variantes = [];
  }
}

class Variante {
  late int itemId;
  late String codItem;
  late int stockTotal;
  late int stockAlmacen;
  late int existenciaActualUbi;
  late dynamic existenciaMaximaUbi;
  late dynamic existenciaMinimaUbi;

  Variante({
    required this.itemId,
    required this.codItem,
    required this.stockTotal,
    required this.stockAlmacen,
    required this.existenciaActualUbi,
    required this.existenciaMaximaUbi,
    required this.existenciaMinimaUbi,
  });

  factory Variante.fromMap(Map<String, dynamic> json) => Variante(
    itemId: json["itemId"] as int? ?? 0,
    codItem: json["codItem"] as String? ?? '',
    stockTotal: json["stockTotal"] as int? ?? 0,
    stockAlmacen: json["stockAlmacen"] as int? ?? 0,
    existenciaActualUbi: json["existenciaActualUbi"] as int? ?? 0,
    existenciaMaximaUbi: json["existenciaMaximaUbi"] as int? ?? 0,
    existenciaMinimaUbi: json["existenciaMinimaUbi"] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => {
    "itemId": itemId,
    "codItem": codItem,
    "stockTotal": stockTotal,
    "stockAlmacen": stockAlmacen,
    "existenciaActualUbi": existenciaActualUbi,
    "existenciaMaximaUbi": existenciaMaximaUbi,
    "existenciaMinimaUbi": existenciaMinimaUbi,
  };

  Variante.empty () {
    itemId = 0;
    codItem = '';
    stockTotal = 0;
    stockAlmacen = 0;
    existenciaActualUbi = 0;
    existenciaMaximaUbi = 0;
    existenciaMinimaUbi = 0;
  }
}
