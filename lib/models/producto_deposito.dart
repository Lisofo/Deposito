// To parse this JSON data, do
//
//     final productoDeposito = productoDepositoFromJson(jsonString);

import 'dart:convert';

List<ProductoDeposito> productoDepositoFromJson(String str) => List<ProductoDeposito>.from(json.decode(str).map((x) => ProductoDeposito.fromJson(x)));

String productoDepositoToJson(List<ProductoDeposito> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ProductoDeposito {
  late String raiz;
  late String descripcion;
  late String modelos;
  late List<Variante> variantes;

  ProductoDeposito({
    required this.raiz,
    required this.descripcion,
    required this.modelos,
    required this.variantes,
  });

  factory ProductoDeposito.fromJson(Map<String, dynamic> json) => ProductoDeposito(
    raiz: json["raiz"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    modelos: json["modelos"] as String? ?? '',
    variantes: List<Variante>.from(json["variantes"].map((x) => Variante.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "raiz": raiz,
    "descripcion": descripcion,
    "variantes": List<dynamic>.from(variantes.map((x) => x.toJson())),
  };

  ProductoDeposito.empty() {
    raiz = '';
    descripcion = '';
    modelos = '';
    variantes = [];
  }
}

class Variante {
  int itemId;
  String codItem;
  int stockTotal;
  List<Almacene> almacenes;

  Variante({
    required this.itemId,
    required this.codItem,
    required this.stockTotal,
    required this.almacenes,
  });

  factory Variante.fromJson(Map<String, dynamic> json) => Variante(
    itemId: json["itemId"],
    codItem: json["codItem"] as String? ?? '',
    stockTotal: json["stockTotal"],
    almacenes: List<Almacene>.from(json["almacenes"].map((x) => Almacene.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "itemId": itemId,
    "codItem": codItem,
    "stockTotal": stockTotal,
    "almacenes": List<dynamic>.from(almacenes.map((x) => x.toJson())),
  };
}

class Almacene {
  late int almacenId;
  late String codAlmacen;
  late String descAlmacen;
  late int stockAlmacen;
  late dynamic existenciaMaximaAlm;
  late dynamic existenciaMinimaAlm;
  late List<dynamic> ubicaciones;

  Almacene({
    required this.almacenId,
    required this.codAlmacen,
    required this.descAlmacen,
    required this.stockAlmacen,
    required this.existenciaMaximaAlm,
    required this.existenciaMinimaAlm,
    required this.ubicaciones,
  });

  factory Almacene.fromJson(Map<String, dynamic> json) => Almacene(
    almacenId: json["almacenId"],
    codAlmacen: json["codAlmacen"] as String? ?? '',
    descAlmacen: json["descAlmacen"] as String? ?? '',
    stockAlmacen: json["stockAlmacen"],
    existenciaMaximaAlm: json["existenciaMaximaAlm"],
    existenciaMinimaAlm: json["existenciaMinimaAlm"],
    ubicaciones: List<dynamic>.from(json["ubicaciones"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "almacenId": almacenId,
    "codAlmacen": codAlmacen,
    "descAlmacen": descAlmacen,
    "stockAlmacen": stockAlmacen,
    "existenciaMaximaAlm": existenciaMaximaAlm,
    "existenciaMinimaAlm": existenciaMinimaAlm,
    "ubicaciones": List<dynamic>.from(ubicaciones.map((x) => x)),
  };

  Almacene.empty() {
    almacenId = 0;
    codAlmacen = '';
    descAlmacen = '';
    stockAlmacen = 0;
    existenciaMaximaAlm = null;
    existenciaMinimaAlm = null;
    ubicaciones = [];
  }
}
