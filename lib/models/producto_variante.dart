// ignore_for_file: prefer_null_aware_operators

import 'linea.dart';

class ProductoVariante {

  late int itemId;
  late String codItem;
  late int monedaId;
  late String signo;
  late double precioVentaActual;
  late double precioIvaIncluido;
  late int existenciaActual;
  late int existenciaTotal;
  late int ivaId;
  late int valor;
  late String codColor;
  late String color;
  late String talle;
  late int disponible;
  late int colorHexCode;
  late int r;
  late int g;
  late int b;
  late int cantidad;
  late List<dynamic> imagenes;
  late int ordenTalle;

  ProductoVariante({
    required this.itemId,
    required this.codItem,
    required this.monedaId,
    required this.signo,
    required this.precioVentaActual,
    required this.precioIvaIncluido,
    required this.existenciaActual,
    required this.existenciaTotal,
    required this.ivaId,
    required this.valor,
    required this.codColor,
    required this.color,
    required this.talle,
    required this.disponible,
    required this.colorHexCode,
    required this.r,
    required this.g,
    required this.b,
    required this.imagenes,
    required this.cantidad,
    required this.ordenTalle,
  });

  static ProductoVariante fromJson(Map<String, dynamic> json) {
    return ProductoVariante(
      signo: json['signo'] as String? ?? '',
      color: json['color'] as String? ?? '',
      itemId: json['itemId'] as int? ?? 0,
      codItem: json['codItem'] as String? ?? '',
      monedaId: json['monedaId'] as int? ?? 0,
      precioVentaActual: json['precioVentaActual'] == null ? null : json['precioVentaActual'].toDouble(),
      existenciaActual: json['existenciaActual'] as int? ?? 0,
      precioIvaIncluido: json['precioIvaIncluido'] == null ? null : json['precioIvaIncluido'].toDouble(),
      existenciaTotal: json['existenciaTotal'] as int? ?? 0,
      ivaId: json['ivaId'] as int? ?? 0,
      valor: json['valor'] as int? ?? 0,
      colorHexCode: int.parse(json['colorHexCode'] ?? '0'),
      talle: json['talle'] as String? ?? '',
      r: json['R'] as int? ?? 0,
      g: json['G'] as int? ?? 0,
      b: json['B'] as int? ?? 0,
      disponible: json['disponible'] as int? ?? 0, 
      codColor: json['codColor'] as String? ?? '',
      imagenes: json['fotosUrl'] as List<dynamic>,
      cantidad: 0,
      ordenTalle: json['ordenTalle'] as int? ?? 0,
    );
  }


  ProductoVariante.empty(){
    itemId = 0;
    codItem = '';
    monedaId = 0;
    signo = '';
    precioVentaActual = 0.0;
    precioIvaIncluido = 0.0;
    existenciaActual = 0;
    existenciaTotal = 0;
    ivaId = 0;
    valor = 0;
    codColor = '';
    color = '';
    talle = '';
    disponible = 0;
    colorHexCode = 0;
    r = 0;
    g = 0;
    b = 0;
    imagenes = [];
    cantidad = 0;
    ordenTalle = 0;
  }

  map(Linea Function(dynamic producto) param0) {}

}

