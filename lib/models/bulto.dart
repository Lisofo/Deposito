class Bulto {
  final int bultoId;
  final int entregaId;
  final int? clienteId;
  final String? nombreCliente;
  final DateTime fechaDate;
  final DateTime fechaBulto;
  final String estado;
  final int almacenId;
  final int? modoEnvioId;
  final int? agenciaTrId;
  final String? comentarioEnvio;
  final String? direccion;
  final String? localidad;
  final String? telefono;
  final int? agenciaUFId;
  final int tipoBultoId;
  final String? comentario;
  final int? retiroId;
  final int armadoPorUsuId;
  final int? nroBulto;
  final int? totalBultos;
  final int? despachoId;
  final int? devolucionId;
  final bool? incluyeFactura;
  late List<BultoItem> contenido;

  Bulto({
    required this.bultoId,
    required this.entregaId,
    this.clienteId,
    this.nombreCliente,
    required this.fechaDate,
    required this.fechaBulto,
    required this.estado,
    required this.almacenId,
    this.modoEnvioId,
    this.agenciaTrId,
    this.comentarioEnvio,
    this.direccion,
    this.localidad,
    this.telefono,
    this.agenciaUFId,
    required this.tipoBultoId,
    this.comentario,
    this.retiroId,
    required this.armadoPorUsuId,
    this.nroBulto,
    this.totalBultos,
    this.despachoId,
    this.devolucionId,
    this.incluyeFactura,
    required this.contenido
  });

  factory Bulto.fromJson(Map<String, dynamic> json) => Bulto(
    bultoId: json["bultoId"] as int? ?? 0,
    entregaId: json["entregaId"] as int? ?? 0,
    clienteId: json["clienteId"] as int?,
    nombreCliente: json["nombreCliente"] as String?,
    fechaDate: DateTime.parse(json["fechaDate"]),
    fechaBulto: DateTime.parse(json["fechaBulto"]),
    estado: json["estado"] as String? ?? '',
    almacenId: json["almacenId"] as int? ?? 0,
    modoEnvioId: json["modoEnvioId"] as int?,
    agenciaTrId: json["agenciaTrId"] as int?,
    comentarioEnvio: json["comentarioEnvio"] as String?,
    direccion: json["direccion"] as String?,
    localidad: json["localidad"] as String?,
    telefono: json["telefono"] as String?,
    agenciaUFId: json["agenciaUFId"] as int?,
    tipoBultoId: json["tipoBultoId"] as int? ?? 0,
    comentario: json["comentario"] as String?,
    retiroId: json["retiroId"] as int?,
    armadoPorUsuId: json["armadoPorUsuId"] as int? ?? 0,
    nroBulto: json["nroBulto"] as int?,
    totalBultos: json["totalBultos"] as int?,
    despachoId: json["despachoId"] as int?,
    devolucionId: json["devolucionId"] as int?,
    incluyeFactura: json["incluyeFactura"] as bool?,
    contenido: []
  );

  Map<String, dynamic> toJson() => {
    "bultoId": bultoId,
    "entregaId": entregaId,
    "clienteId": clienteId,
    "nombreCliente": nombreCliente,
    "fechaDate": fechaDate.toIso8601String(),
    "fechaBulto": fechaBulto.toIso8601String(),
    "estado": estado,
    "almacenId": almacenId,
    "modoEnvioId": modoEnvioId,
    "agenciaTrId": agenciaTrId,
    "comentarioEnvio": comentarioEnvio,
    "direccion": direccion,
    "localidad": localidad,
    "telefono": telefono,
    "agenciaUFId": agenciaUFId,
    "tipoBultoId": tipoBultoId,
    "comentario": comentario,
    "retiroId": retiroId,
    "armadoPorUsuId": armadoPorUsuId,
    "nroBulto": nroBulto,
    "totalBultos": totalBultos,
    "despachoId": despachoId,
    "devolucionId": devolucionId,
    "incluyeFactura": incluyeFactura,
  };

  factory Bulto.empty() => Bulto(
    bultoId: 0,
    entregaId: 0,
    fechaDate: DateTime.now(),
    fechaBulto: DateTime.now(),
    estado: '',
    almacenId: 0,
    tipoBultoId: 0,
    armadoPorUsuId: 0,
    contenido: []
  );

  Bulto copyWith({
    int? bultoId,
    int? entregaId,
    int? clienteId,
    String? nombreCliente,
    DateTime? fechaDate,
    DateTime? fechaBulto,
    String? estado,
    int? almacenId,
    int? modoEnvioId,
    int? agenciaTrId,
    String? comentarioEnvio,
    String? direccion,
    String? localidad,
    String? telefono,
    int? agenciaUFId,
    int? tipoBultoId,
    String? comentario,
    int? retiroId,
    int? armadoPorUsuId,
    int? nroBulto,
    int? totalBultos,
    int? despachoId,
    int? devolucionId,
    bool? incluyeFactura,
    List<BultoItem>? contenido,
  }) {
    return Bulto(
      bultoId: bultoId ?? this.bultoId,
      entregaId: entregaId ?? this.entregaId,
      clienteId: clienteId ?? this.clienteId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      fechaDate: fechaDate ?? this.fechaDate,
      fechaBulto: fechaBulto ?? this.fechaBulto,
      estado: estado ?? this.estado,
      almacenId: almacenId ?? this.almacenId,
      modoEnvioId: modoEnvioId ?? this.modoEnvioId,
      agenciaTrId: agenciaTrId ?? this.agenciaTrId,
      comentarioEnvio: comentarioEnvio ?? this.comentarioEnvio,
      direccion: direccion ?? this.direccion,
      localidad: localidad ?? this.localidad,
      telefono: telefono ?? this.telefono,
      agenciaUFId: agenciaUFId ?? this.agenciaUFId,
      tipoBultoId: tipoBultoId ?? this.tipoBultoId,
      comentario: comentario ?? this.comentario,
      retiroId: retiroId ?? this.retiroId,
      armadoPorUsuId: armadoPorUsuId ?? this.armadoPorUsuId,
      nroBulto: nroBulto ?? this.nroBulto,
      totalBultos: totalBultos ?? this.totalBultos,
      despachoId: despachoId ?? this.despachoId,
      devolucionId: devolucionId ?? this.devolucionId,
      incluyeFactura: incluyeFactura ?? this.incluyeFactura,
      contenido: contenido ?? this.contenido,
    );
  }
}

class BultoItem {
  late int pickId;
  late int pickLineaId;
  late int bultoLinId;
  late int bultoId;
  late int itemId;
  late int cantidad;
  late int cantidadMaxima;
  late String raiz;
  late String codItem;
  late String item;

  BultoItem({
    required this.pickId,
    required this.pickLineaId,
    required this.bultoLinId,
    required this.bultoId,
    required this.itemId,
    required this.cantidad,
    required this.cantidadMaxima,
    required this.raiz,
    required this.codItem,
    required this.item,
  });

  factory BultoItem.fromJson(Map<String, dynamic> json) => BultoItem(
    pickId: json["pickId"] as int? ?? 0,
    pickLineaId: json["pickLineaId"] as int? ?? 0,
    bultoLinId: json["bultoLinId"] as int? ?? 0,
    bultoId: json["bultoId"] as int? ?? 0,
    itemId: json["itemId"] as int? ?? 0,
    cantidad: json["cantidad"] as int? ?? 0,
    cantidadMaxima: 0,
    raiz: json["raiz"] as String? ?? '',
    codItem: json['codItem'] as String? ?? '',
    item: json['item'] as String? ?? ''
  );

  Map<String, dynamic> toJson() => {
    "bultoLinId": bultoLinId,
    "bultoId": bultoId,
    "pickLineaId": pickLineaId,
    "cantidad": cantidad,
  };

  factory BultoItem.empty() => BultoItem(
    bultoLinId: 0,
    bultoId: 0,
    pickLineaId: 0,
    cantidad: 0,
    cantidadMaxima: 0,
    raiz: '',
    codItem: '',
    item: '',
    pickId: 0,
    itemId: 0,
  );

  BultoItem copyWith({
    int? pickId,
    int? pickLineaId,
    int? bultoLinId,
    int? bultoId,
    int? itemId,
    int? cantidad,
    int? cantidadMaxima,
    String? raiz,
    String? codItem,
    String? item,
  }) {
    return BultoItem(
      pickId: pickId ?? this.pickId,
      pickLineaId: pickLineaId ?? this.pickLineaId,
      bultoLinId: bultoLinId ?? this.bultoLinId,
      bultoId: bultoId ?? this.bultoId,
      itemId: itemId ?? this.itemId,
      cantidad: cantidad ?? this.cantidad,
      cantidadMaxima: cantidadMaxima ?? this.cantidadMaxima,
      raiz: raiz ?? this.raiz,
      codItem: codItem ?? this.codItem,
      item: item ?? this.item,
    );
  }
}