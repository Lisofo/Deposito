// ignore_for_file: prefer_null_aware_operators
import 'producto_variante.dart';

class Product {
  late String codAlmacen;
  late String raiz;
  late String descripcion;
  late int monedaId;
  late String memo;
  late String signo;
  late double precioVentaActual;
  late double precioIvaIncluido; 
  late int ivaId;
  late int valor;
  late int disponibleRaiz;
  late int existenciaRaiz;
  late List<ProductoVariante> variantes;
  late List<dynamic> imagenes;

  Product({
    required this.codAlmacen,
    required this.raiz,
    required this.descripcion,
    required this.monedaId,
    required this.memo,
    required this.signo,
    required this.precioVentaActual,
    required this.precioIvaIncluido,
    required this.ivaId,
    required this.valor,
    required this.disponibleRaiz,
    required this.existenciaRaiz,
    required this.variantes,
    required this.imagenes  
    
  });

  static Product fromJson(Map<String, dynamic> json) {
    return Product(
      codAlmacen: json['CodAlmacen'] as String? ?? '',
      raiz: json['Raiz'] as String? ?? '',
      descripcion: json['Descripcion'] as String? ?? '',
      monedaId: json['MonedaId'] as int? ?? 0,
      memo: json['Memo'] as String? ?? '',
      signo: json['Signo'] as String? ?? '',
      precioVentaActual: json['PrecioVentaActual'] == null ? null : json['PrecioVentaActual'].toDouble(),
      precioIvaIncluido: json['PrecioIvaIncluido'] == null ? null : json['PrecioIvaIncluido'].toDouble(),
      ivaId: json['IvaId'] as int? ?? 0,
      valor: json['Valor'] as int? ?? 0,
      disponibleRaiz: json['DisponibleRaiz'] as int? ?? 0,
      existenciaRaiz: json['ExistenciaRaiz'] as int? ?? 0,
      variantes: List<ProductoVariante>.from(json["variantes"].map((x)=> ProductoVariante.fromJson(x))).toList(),
      imagenes: json['FotosUrl'] as List<dynamic>,

      
      
    );
  }

  Product.empty() {
    codAlmacen = '';
    raiz = '';
    descripcion = '';
    monedaId = 0;
    memo = '';
    signo = '';
    precioVentaActual = 0.0;
    precioIvaIncluido = 0.0;
    ivaId = 0;
    valor = 0;
    disponibleRaiz = 0;
    existenciaRaiz = 0;
    variantes = [];
    imagenes = [];
    
    
  }

  @override
  String toString() {
    return 'Instance of Product: $descripcion';
  }
}

