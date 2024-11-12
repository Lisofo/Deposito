class Linea {
  late int lineaId;
  late int ordenTrabajoId;
  late String numeroOrdenTrabajo;
  late int monedaId;
  late DateTime? fechaOrdenTrabajo;
  late String estado;
  late int itemId;
  late String? raizEstricta;
  late int? raizCantidad;
  late String codItem;
  late String raiz;
  late String descripcion;
  late String macroFamilia;
  late String familia;
  late String grupoInventario;
  late int ordinal;
  late int cantidad;
  late double costoUnitario;
  late int descuento1;
  late int descuento2;
  late int descuento3;
  late int precioVenta;
  late String comentario;
  late int ivaId;
  late String iva;
  late int valor;
  late int gruInvId;
  late String codGruInv;
  late int cantFacturada;
  late int cantDevuelta;
  late double totNetoFacturada;
  late double totBrutoFacturada;
  late int cantFac;
  late int cantRem;
  late double netoFac;
  late double netoRem;
  late double brutoFac;
  late double brutoRem;
  late int cantEPend;
  late String fotoURL;
  late String codColor;
  late String color;
  late String colorHexCode;
  late int R;
  late int G;
  late int B;
  late String talle;
  late bool isExpanded;
  late String metodo;
  late int ordenTalle;

  Linea({
    required this.lineaId,
    required this.ordenTrabajoId,
    required this.numeroOrdenTrabajo,
    required this.monedaId,
    required this.fechaOrdenTrabajo,
    required this.estado,
    required this.itemId,
    this.raizEstricta,
    this.raizCantidad,
    required this.codItem,
    required this.raiz,
    required this.descripcion,
    required this.macroFamilia,
    required this.familia,
    required this.grupoInventario,
    required this.ordinal,
    required this.cantidad,
    required this.costoUnitario,
    required this.descuento1,
    required this.descuento2,
    required this.descuento3,
    required this.precioVenta,
    required this.comentario,
    required this.ivaId,
    required this.iva,
    required this.valor,
    required this.gruInvId,
    required this.codGruInv,
    required this.cantFacturada,
    required this.cantDevuelta,
    required this.totNetoFacturada,
    required this.totBrutoFacturada,
    required this.cantFac,
    required this.cantRem,
    required this.netoFac,
    required this.netoRem,
    required this.brutoFac,
    required this.brutoRem,
    required this.cantEPend,
    required this.fotoURL,
    required this.codColor,
    required this.color,
    required this.colorHexCode,
    required this.R,
    required this.G,
    required this.B,
    required this.talle,
    this.isExpanded = false,
    required this.metodo,
    required this.ordenTalle,
  });

   // Constructor de copia
  Linea.copy(Linea linea)
    : lineaId = linea.lineaId,
      ordenTrabajoId = linea.ordenTrabajoId,
      numeroOrdenTrabajo = linea.numeroOrdenTrabajo,
      monedaId = linea.monedaId,
      fechaOrdenTrabajo = linea.fechaOrdenTrabajo,
      estado = linea.estado,
      itemId = linea.itemId,
      raizEstricta = linea.raizEstricta,
      raizCantidad = linea.raizCantidad,
      codItem = linea.codItem,
      raiz = linea.raiz,
      descripcion = linea.descripcion,
      macroFamilia = linea.macroFamilia,
      familia = linea.familia,
      grupoInventario = linea.grupoInventario,
      ordinal = linea.ordinal,
      cantidad = linea.cantidad,
      costoUnitario = linea.costoUnitario,
      descuento1 = linea.descuento1,
      descuento2 = linea.descuento2,
      descuento3 = linea.descuento3,
      precioVenta = linea.precioVenta,
      comentario = linea.comentario,
      ivaId = linea.ivaId,
      iva = linea.iva,
      valor = linea.valor,
      gruInvId = linea.gruInvId,
      codGruInv = linea.codGruInv,
      cantFacturada = linea.cantFacturada,
      cantDevuelta = linea.cantDevuelta,
      totNetoFacturada = linea.totNetoFacturada,
      totBrutoFacturada = linea.totBrutoFacturada,
      cantFac = linea.cantFac,
      cantRem = linea.cantRem,
      netoFac = linea.netoFac,
      netoRem = linea.netoRem,
      brutoFac = linea.brutoFac,
      brutoRem = linea.brutoRem,
      cantEPend = linea.cantEPend,
      fotoURL = linea.fotoURL,
      codColor = linea.codColor,
      color = linea.color,
      colorHexCode = linea.colorHexCode,
      R = linea.R,
      G = linea.G,
      B = linea.B,
      talle = linea.talle,
      isExpanded = linea.isExpanded,
      metodo = linea.metodo,
      ordenTalle = linea.ordenTalle;

  factory Linea.fromJson(Map<String, dynamic> json) => Linea(
    lineaId: json["lineaId"] as int? ?? 0,
    ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
    numeroOrdenTrabajo: json["numeroOrdenTrabajo"] as String? ?? '',
    monedaId: json["monedaId"] as int? ?? 0,
    fechaOrdenTrabajo: json["fechaOrdenTrabajo"] != null ? DateTime.parse(json["fechaOrdenTrabajo"]) : null,
    estado: json["estado"] as String? ?? '',
    itemId: json["itemId"] as int? ?? 0,
    raizEstricta: json["raizEstricta"] as String?,
    raizCantidad: json["raizCantidad"] as int?,
    codItem: json["codItem"] as String? ?? '',
    raiz: json["raiz"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    macroFamilia: json["macroFamilia"] as String? ?? '',
    familia: json["familia"] as String? ?? '',
    grupoInventario: json["grupoInventario"] as String? ?? '',
    ordinal: json["ordinal"] as int? ?? 0,
    cantidad: json["cantidad"] as int? ?? 0,
    costoUnitario: json["costoUnitario"].toDouble(),
    descuento1: json["descuento1"] as int? ?? 0,
    descuento2: json["descuento2"] as int? ?? 0,
    descuento3: json["descuento3"] as int? ?? 0,
    precioVenta: json["precioVenta"] as int? ?? 0,
    comentario: json["comentario"] as String? ?? '',
    ivaId: json["ivaId"] as int? ?? 0,
    iva: json["IVA"] as String? ?? '',
    valor: json["valor"] as int? ?? 0,
    gruInvId: json["gruInvId"] as int? ?? 0,
    codGruInv: json["codGruInv"] as String? ?? '',
    cantFacturada: json["cantFacturada"] as int? ?? 0,
    cantDevuelta: json["cantDevuelta"] as int? ?? 0,
    totNetoFacturada: json["totNetoFacturada"].toDouble(),
    totBrutoFacturada: json["totBrutoFacturada"].toDouble(),
    cantFac: json["cantFac"] as int? ?? 0,
    cantRem: json["cantRem"] as int? ?? 0,
    netoFac: json["netoFac"].toDouble(),
    netoRem: json["netoRem"].toDouble(),
    brutoFac: json["brutoFac"].toDouble(),
    brutoRem: json["brutoRem"].toDouble(),
    cantEPend: json["cantEPend"] as int? ?? 0,
    fotoURL: json["fotoURL"] as String? ?? '',
    codColor: json["codColor"] as String? ?? '',
    color: json["color"] as String? ?? '',
    colorHexCode: json["colorHexCode"] as String? ?? '',
    R: json["R"] as int? ?? 0,
    G: json["G"] as int? ?? 0,
    B: json["B"] as int? ?? 0,
    talle: json["talle"] as String? ?? '',
    metodo: '',
    ordenTalle: json['ordenTalle'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "lineaId": lineaId,
    "ordenTrabajoId": ordenTrabajoId,
    "numeroOrdenTrabajo": numeroOrdenTrabajo,
    "monedaId": monedaId,
    "fechaOrdenTrabajo": fechaOrdenTrabajo?.toIso8601String(),
    "estado": estado,
    "itemId": itemId,
    "raizEstricta": raizEstricta,
    "raizCantidad": raizCantidad,
    "codItem": codItem,
    "raiz": raiz,
    "descripcion": descripcion,
    "macroFamilia": macroFamilia,
    "familia": familia,
    "grupoInventario": grupoInventario,
    "ordinal": ordinal,
    "cantidad": cantidad,
    "costoUnitario": costoUnitario,
    "descuento1": descuento1,
    "descuento2": descuento2,
    "descuento3": descuento3,
    "precioVenta": precioVenta,
    "comentario": comentario,
    "ivaId": ivaId,
    "IVA": iva,
    "valor": valor,
    "gruInvId": gruInvId,
    "codGruInv": codGruInv,
    "cantFacturada": cantFacturada,
    "cantDevuelta": cantDevuelta,
    "totNetoFacturada": totNetoFacturada,
    "totBrutoFacturada": totBrutoFacturada,
    "cantFac": cantFac,
    "cantRem": cantRem,
    "netoFac": netoFac,
    "netoRem": netoRem,
    "brutoFac": brutoFac,
    "brutoRem": brutoRem,
    "cantEPend": cantEPend,
    "fotoURL": fotoURL,
    "codColor": codColor,
    "color": color,
    "colorHexCode": colorHexCode,
    "R": R,
    "G": G,
    "B": B,
    "talle": talle,
  };

   Linea.empty() {
    lineaId = 0;
    ordenTrabajoId = 0;
    numeroOrdenTrabajo = '';
    monedaId = 0;
    fechaOrdenTrabajo = null;
    estado = '';
    itemId = 0;
    raizEstricta = null;
    raizCantidad = null;
    codItem = '';
    raiz = '';
    descripcion = '';
    macroFamilia = '';
    familia = '';
    grupoInventario = '';
    ordinal = 0;
    cantidad = 0;
    costoUnitario = 0;
    descuento1 = 0;
    descuento2 = 0;
    descuento3 = 0;
    precioVenta = 0;
    comentario = '';
    ivaId = 0;
    iva = '';
    valor = 0;
    gruInvId = 0;
    codGruInv = '';
    cantFacturada = 0;
    cantDevuelta = 0;
    totNetoFacturada = 0;
    totBrutoFacturada = 0;
    cantFac = 0;
    cantRem = 0;
    netoFac = 0;
    netoRem = 0;
    brutoFac = 0;
    brutoRem = 0;
    cantEPend = 0;
    fotoURL = '';
    codColor = '';
    color = '';
    colorHexCode = '';
    R = 0;
    G = 0;
    B = 0;
    talle = '';
    isExpanded = false;
    metodo = '';
    ordenTalle = 0;
  }

  @override
  String toString() {
    return raiz;
  }
}
