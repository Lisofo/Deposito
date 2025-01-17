// To parse this JSON data, do
//
//     final productoDeposito = productoDepositoFromJson(jsonString);

import 'dart:convert';

ProductoDeposito productoDepositoFromJson(String str) => ProductoDeposito.fromJson(json.decode(str));

String productoDepositoToJson(ProductoDeposito data) => json.encode(data.toJson());

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
  late List<Ubicacione> ubicaciones;

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
    ubicaciones: List<Ubicacione>.from(json["ubicaciones"].map((x) => Ubicacione.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "almacenId": almacenId,
    "codAlmacen": codAlmacen,
    "descAlmacen": descAlmacen,
    "stockAlmacen": stockAlmacen,
    "existenciaMaximaAlm": existenciaMaximaAlm,
    "existenciaMinimaAlm": existenciaMinimaAlm,
    "ubicaciones": List<dynamic>.from(ubicaciones.map((x) => x.toJson())),
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

class Ubicacione {
  late int almacenUbicacionId;
  late String codUbicacion;
  late String descUbicacion;
  late int existenciaActualUbi;
  late int capacidad;
  late int orden;

  Ubicacione({
    required this.almacenUbicacionId,
    required this.codUbicacion,
    required this.descUbicacion,
    required this.existenciaActualUbi,
    required this.capacidad,
    required this.orden,
  });

  factory Ubicacione.fromJson(Map<String, dynamic> json) => Ubicacione(
    almacenUbicacionId: json["almacenUbicacionId"],
    codUbicacion: json["codUbicacion"],
    descUbicacion: json["descUbicacion"],
    existenciaActualUbi: json["existenciaActualUbi"],
    capacidad: json["capacidad"],
    orden: json["orden"],
  );

  Map<String, dynamic> toJson() => {
    "almacenUbicacionId": almacenUbicacionId,
    "codUbicacion": codUbicacion,
    "descUbicacion": descUbicacion,
    "existenciaActualUbi": existenciaActualUbi,
    "capacidad": capacidad,
    "orden": orden,
  };
}
