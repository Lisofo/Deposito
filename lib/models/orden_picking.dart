// To parse this JSON data, do
//
//     final ordenPicking = ordenPickingFromJson(jsonString);

import 'dart:convert';

OrdenPicking ordenPickingFromJson(String str) => OrdenPicking.fromJson(json.decode(str));

String ordenPickingToJson(OrdenPicking data) => json.encode(data.toJson());

class OrdenPicking {
  late int pickId;
  late int numeroDocumento;
  late String? serie;
  late int transaccionId;
  late String transaccion;
  late String tipo;
  late String descTipo;
  late int movimientoId;
  late DateTime fechaDate;
  late DateTime fechaDocumento;
  late String estado;
  late int almacenIdOrigen;
  late int almacenIdDestino;
  late String prioridad;
  late String comentario;
  late int? cantLineas;
  late int tInfoEmpresaWsId;
  late int usuId;
  late int entidadId;
  late String codEntidad;
  late String ruc;
  late String nombre;
  late String telefono;
  late String localidad;
  late double porcentajeCompletado;
  late String creadoPor;
  late String modificadoPor;
  late DateTime fechaModificadoPor;
  late List<PickingLinea>? lineas;

  OrdenPicking({
    required this.pickId,
    required this.numeroDocumento,
    required this.serie,
    required this.transaccionId,
    required this.transaccion,
    required this.tipo,
    required this.descTipo,
    required this.movimientoId,
    required this.fechaDate,
    required this.fechaDocumento,
    required this.estado,
    required this.almacenIdOrigen,
    required this.almacenIdDestino,
    required this.prioridad,
    required this.comentario,
    required this.cantLineas,
    required this.tInfoEmpresaWsId,
    required this.usuId,
    required this.entidadId,
    required this.codEntidad,
    required this.ruc,
    required this.nombre,
    required this.telefono,
    required this.localidad,
    required this.porcentajeCompletado,
    required this.lineas,
    required this.creadoPor,
    required this.modificadoPor,
    required this.fechaModificadoPor,
  });

  factory OrdenPicking.fromJson(Map<String, dynamic> json) => OrdenPicking(
    pickId: json["pickId"] as int? ?? 0,
    numeroDocumento: json["numeroDocumento"] as int? ?? 0,
    serie: json["serie"] as String? ?? '',
    transaccionId: json["transaccionId"] as int? ?? 0,
    transaccion: json["transaccion"] as String? ?? '',
    tipo: json["tipo"] as String? ?? '',
    descTipo: json["descTipo"] as String? ?? '',
    movimientoId: json["movimientoId"] as int? ?? 0,
    fechaDate: DateTime.parse(json["fechaDate"]),
    fechaDocumento: DateTime.parse(json["fechaDocumento"]),
    estado: json["estado"] as String? ?? '',
    almacenIdOrigen: json["almacenIdOrigen"] as int? ?? 0,
    almacenIdDestino: json["almacenIdDestino"] as int? ?? 0,
    prioridad: json["prioridad"] as String? ?? '',
    comentario: json["comentario"] as String? ?? '',
    cantLineas: json["cantLineas"] as int? ?? 0,
    tInfoEmpresaWsId: json["tInfoEmpresaWSId"] as int? ?? 0,
    usuId: json["usuId"] as int? ?? 0,
    entidadId: json["entidadId"] as int? ?? 0,
    codEntidad: json["codEntidad"] as String? ?? '',
    ruc: json["ruc"] as String? ?? '',
    nombre: json["nombre"] as String? ?? '',
    telefono: json["telefono"] as String? ?? '',
    localidad: json["localidad"] as String? ?? '',
    porcentajeCompletado: (json["porcentajeCompletado"] is int) 
        ? (json["porcentajeCompletado"] as int).toDouble() 
        : json["porcentajeCompletado"] as double? ?? 0.0,
    creadoPor: json["creadoPor"] as String? ?? '',
    modificadoPor: json["modificadoPor"] as String? ?? '',
    fechaModificadoPor: DateTime.parse(json["fechaModificadoPor"]),
    lineas: json["lineas"] != null 
        ? List<PickingLinea>.from(json["lineas"].map((x) => PickingLinea.fromJson(x))) 
        : [],
  );

  Map<String, dynamic> toJson() => {
    "pickId": pickId,
    "numeroDocumento": numeroDocumento,
    "serie": serie,
    "transaccionId": transaccionId,
    "transaccion": transaccion,
    "tipo": tipo,
    "descTipo": descTipo,
    "movimientoId": movimientoId,
    "fechaDate": fechaDate.toIso8601String(),
    "fechaDocumento": fechaDocumento.toIso8601String(),
    "estado": estado,
    "almacenIdOrigen": almacenIdOrigen,
    "almacenIdDestino": almacenIdDestino,
    "prioridad": prioridad,
    "comentario": comentario,
    "cantLineas": cantLineas,
    "tInfoEmpresaWSId": tInfoEmpresaWsId,
    "usuId": usuId,
    "entidadId": entidadId,
    "codEntidad": codEntidad,
    "ruc": ruc,
    "nombre": nombre,
    "telefono": telefono,
    "localidad": localidad,
    "porcentajeCompletado": porcentajeCompletado,
    "lineas": List<dynamic>.from(lineas!.map((x) => x.toJson())),
  };

  OrdenPicking.empty() {
    pickId = 0;
    numeroDocumento = 0;
    serie = '';
    transaccionId = 0;
    transaccion = '';
    tipo = '';
    descTipo = '';
    movimientoId = 0;
    fechaDate = DateTime.now();
    fechaDocumento = DateTime.now();
    fechaModificadoPor = DateTime.now();
    estado = '';
    almacenIdOrigen = 0;
    almacenIdDestino = 0;
    prioridad = '';
    comentario = '';
    cantLineas = 0;
    tInfoEmpresaWsId = 0;
    usuId = 0;
    entidadId = 0;
    porcentajeCompletado = 0.0;
    codEntidad = '';
    ruc = '';
    nombre = '';
    telefono = '';
    localidad = '';
    creadoPor = '';
    modificadoPor = '';
    lineas = [];
  }

  OrdenPicking copyWith({
    int? pickId,
    int? numeroDocumento,
    String? serie,
    int? transaccionId,
    String? transaccion,
    String? tipo,
    String? descTipo,
    int? movimientoId,
    DateTime? fechaDate,
    DateTime? fechaDocumento,
    String? estado,
    int? almacenIdOrigen,
    int? almacenIdDestino,
    String? prioridad,
    String? comentario,
    int? cantLineas,
    int? tInfoEmpresaWsId,
    int? usuId,
    int? entidadId,
    String? codEntidad,
    String? ruc,
    String? nombre,
    String? telefono,
    String? localidad,
    double? porcentajeCompletado,
    String? creadoPor,
    String? modificadoPor,
    DateTime? fechaModificadoPor,
    List<PickingLinea>? lineas,
  }) {
    return OrdenPicking(
      pickId: pickId ?? this.pickId,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      serie: serie ?? this.serie,
      transaccionId: transaccionId ?? this.transaccionId,
      transaccion: transaccion ?? this.transaccion,
      tipo: tipo ?? this.tipo,
      descTipo: descTipo ?? this.descTipo,
      movimientoId: movimientoId ?? this.movimientoId,
      fechaDate: fechaDate ?? this.fechaDate,
      fechaDocumento: fechaDocumento ?? this.fechaDocumento,
      estado: estado ?? this.estado,
      almacenIdOrigen: almacenIdOrigen ?? this.almacenIdOrigen,
      almacenIdDestino: almacenIdDestino ?? this.almacenIdDestino,
      prioridad: prioridad ?? this.prioridad,
      comentario: comentario ?? this.comentario,
      cantLineas: cantLineas ?? this.cantLineas,
      tInfoEmpresaWsId: tInfoEmpresaWsId ?? this.tInfoEmpresaWsId,
      usuId: usuId ?? this.usuId,
      entidadId: entidadId ?? this.entidadId,
      codEntidad: codEntidad ?? this.codEntidad,
      ruc: ruc ?? this.ruc,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      localidad: localidad ?? this.localidad,
      porcentajeCompletado: porcentajeCompletado ?? this.porcentajeCompletado,
      creadoPor: creadoPor ?? this.creadoPor,
      modificadoPor: modificadoPor ?? this.modificadoPor,
      fechaModificadoPor: fechaModificadoPor ?? this.fechaModificadoPor,
      lineas: lineas ?? (this.lineas != null ? List.from(this.lineas!) : null),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrdenPicking && other.pickId == pickId;
  }

  @override
  int get hashCode => pickId.hashCode;
}

class PickingLinea {
  late int pickLineaId;
  late int pickId;
  late int lineaId;
  late int itemId;
  late int cantidadPedida;
  late int cantidadPickeada;
  late String tipoLineaAdicional;
  late int lineaIdOriginal;
  late String codItem;
  late String descripcion;
  late List<UbicacionePicking> ubicaciones;

  PickingLinea({
    required this.pickLineaId,
    required this.pickId,
    required this.lineaId,
    required this.itemId,
    required this.cantidadPedida,
    required this.cantidadPickeada,
    required this.tipoLineaAdicional,
    required this.lineaIdOriginal,
    required this.codItem,
    required this.descripcion,
    required this.ubicaciones,
  });

  factory PickingLinea.fromJson(Map<String, dynamic> json) => PickingLinea(
    pickLineaId: json["pickLineaId"] as int? ?? 0,
    pickId: json["pickId"] as int? ?? 0,
    lineaId: json["lineaId"] as int? ?? 0,
    itemId: json["itemId"] as int? ?? 0,
    cantidadPedida: json["cantidadPedida"] as int? ?? 0,
    cantidadPickeada: json["cantidadPickeada"] as int? ?? 0,
    tipoLineaAdicional: json["tipoLineaAdicional"] as String? ?? '',
    lineaIdOriginal: json["lineaIdOriginal"] as int? ?? 0,
    codItem: json["codItem"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    ubicaciones: json["ubicaciones"] != null 
        ? List<UbicacionePicking>.from(json["ubicaciones"].map((x) => UbicacionePicking.fromJson(x))) 
        : [],
  );

  Map<String, dynamic> toJson() => {
    "pickLineaId": pickLineaId,
    "pickId": pickId,
    "lineaId": lineaId,
    "itemId": itemId,
    "cantidadPedida": cantidadPedida,
    "cantidadPickeada": cantidadPickeada,
    "tipoLineaAdicional": tipoLineaAdicional,
    "lineaIdOriginal": lineaIdOriginal,
    "codItem": codItem,
    "descripcion": descripcion,
    "ubicaciones": List<dynamic>.from(ubicaciones.map((x) => x.toJson())),
  };

  PickingLinea.empty() {
    pickLineaId = 0;
    pickId = 0;
    lineaId = 0;
    itemId = 0;
    cantidadPedida = 0;
    cantidadPickeada = 0;
    tipoLineaAdicional = '';
    lineaIdOriginal = 0;
    codItem = '';
    descripcion = '';
    ubicaciones = [];
  }

  PickingLinea copyWith({
    int? pickLineaId,
    int? pickId,
    int? lineaId,
    int? itemId,
    int? cantidadPedida,
    int? cantidadPickeada,
    String? tipoLineaAdicional,
    int? lineaIdOriginal,
    String? codItem,
    String? descripcion,
    List<UbicacionePicking>? ubicaciones,
  }) {
    return PickingLinea(
      pickLineaId: pickLineaId ?? this.pickLineaId,
      pickId: pickId ?? this.pickId,
      lineaId: lineaId ?? this.lineaId,
      itemId: itemId ?? this.itemId,
      cantidadPedida: cantidadPedida ?? this.cantidadPedida,
      cantidadPickeada: cantidadPickeada ?? this.cantidadPickeada,
      tipoLineaAdicional: tipoLineaAdicional ?? this.tipoLineaAdicional,
      lineaIdOriginal: lineaIdOriginal ?? this.lineaIdOriginal,
      codItem: codItem ?? this.codItem,
      descripcion: descripcion ?? this.descripcion,
      // ignore: unnecessary_null_comparison
      ubicaciones: ubicaciones ?? (this.ubicaciones != null ? List.from(this.ubicaciones) : []),
    );
  }
}

class UbicacionePicking {
  late int itemAlmacenUbicacionId;
  late int itemId;
  late int almacenUbicacionId;
  late int existenciaActual;
  late int? existenciaMaxima;
  late int? existenciaMinima;
  late DateTime fechaBaja;
  late String codUbicacion;

  UbicacionePicking({
    required this.itemAlmacenUbicacionId,
    required this.itemId,
    required this.almacenUbicacionId,
    required this.existenciaActual,
    required this.existenciaMaxima,
    required this.existenciaMinima,
    required this.fechaBaja,
    required this.codUbicacion,
  });

  factory UbicacionePicking.fromJson(Map<String, dynamic> json) => UbicacionePicking(
    itemAlmacenUbicacionId: json["itemAlmacenUbicacionId"] as int? ?? 0,
    itemId: json["itemId"] as int? ?? 0,
    almacenUbicacionId: json["almacenUbicacionId"] as int? ?? 0,
    existenciaActual: json["existenciaActual"] as int? ?? 0,
    existenciaMaxima: json["existenciaMaxima"] as int? ?? 0,
    existenciaMinima: json["existenciaMinima"] as int? ?? 0,
    fechaBaja: json["fechaBaja"] != null ? DateTime.parse(json["fechaBaja"]) : DateTime.now(),
    codUbicacion: json["codUbicacion"] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    "ItemAlmacenUbicacionId": itemAlmacenUbicacionId,
    "ItemId": itemId,
    "AlmacenUbicacionId": almacenUbicacionId,
    "ExistenciaActual": existenciaActual,
    "ExistenciaMaxima": existenciaMaxima,
    "ExistenciaMinima": existenciaMinima,
    "fechaBaja": fechaBaja.toIso8601String(),
    "codUbicacion": codUbicacion,
  };

  UbicacionePicking.empty() {
    itemAlmacenUbicacionId = 0;
    itemId = 0;
    almacenUbicacionId = 0;
    existenciaActual = 0;
    existenciaMaxima = 0;
    existenciaMinima = 0;
    fechaBaja = DateTime.now();
    codUbicacion = '';
  }

  UbicacionePicking copyWith({
    int? itemAlmacenUbicacionId,
    int? itemId,
    int? almacenUbicacionId,
    int? existenciaActual,
    int? existenciaMaxima,
    int? existenciaMinima,
    DateTime? fechaBaja,
    String? codUbicacion,
  }) {
    return UbicacionePicking(
      itemAlmacenUbicacionId: itemAlmacenUbicacionId ?? this.itemAlmacenUbicacionId,
      itemId: itemId ?? this.itemId,
      almacenUbicacionId: almacenUbicacionId ?? this.almacenUbicacionId,
      existenciaActual: existenciaActual ?? this.existenciaActual,
      existenciaMaxima: existenciaMaxima ?? this.existenciaMaxima,
      existenciaMinima: existenciaMinima ?? this.existenciaMinima,
      fechaBaja: fechaBaja ?? this.fechaBaja,
      codUbicacion: codUbicacion ?? this.codUbicacion,
    );
  }
}