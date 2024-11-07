// ignore_for_file: prefer_null_aware_operators
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
late List<dynamic> imagenes;

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
  required this.imagenes
});

static ProductoVariante fromJson(Map<String, dynamic> json) {
    return ProductoVariante(
      signo: json['Signo'] as String? ?? '',
      color: json['Color'] as String? ?? '',
      itemId: json['ItemId'] as int? ?? 0,
      codItem: json['CodItem'] as String? ?? '',
      monedaId: json['MonedaId'] as int? ?? 0,
      precioVentaActual: json['PrecioVentaActual'] == null ? null : json['PrecioVentaActual'].toDouble(),
      existenciaActual: json['ExistenciaActual'] as int? ?? 0,
      precioIvaIncluido: json['PrecioIvaIncluido'] == null ? null : json['PrecioIvaIncluido'].toDouble(),
      existenciaTotal: json['ExistenciaTotal'] as int? ?? 0,
      ivaId: json['IvaId'] as int? ?? 0,
      valor: json['Valor'] as int? ?? 0,
      colorHexCode: int.parse(json['ColorHexCode'] ?? '0'),
      talle: json['Talle'] as String? ?? '',
      r: json['R'] as int? ?? 0,
      g: json['G'] as int? ?? 0,
      b: json['B'] as int? ?? 0,
      disponible: json['Disponible'] as int? ?? 0, 
      codColor: json['CodColor'] as String? ?? '',
      imagenes: json['FotosUrl'] as List<dynamic>,

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
}

}

