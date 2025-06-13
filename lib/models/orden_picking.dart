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
  late List<PickingLinea>? lineas;

  OrdenPicking({
    required this.pickId,
    required this.numeroDocumento,
    required this.serie,
    required this.transaccionId,
    required this.transaccion,
    required this.tipo,
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
    required this.lineas,
  });

  factory OrdenPicking.fromJson(Map<String, dynamic> json) => OrdenPicking(
    pickId: json["pickId"] as int? ?? 0,
    numeroDocumento: json["numeroDocumento"] as int? ?? 0,
    serie: json["serie"] as String? ?? '',
    transaccionId: json["transaccionId"] as int? ?? 0,
    transaccion: json["transaccion"] as String? ?? '',
    tipo: json["tipo"] as String? ?? '',
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
    lineas: json["lineas"] != null ? List<PickingLinea>.from(json["lineas"].map((x) => PickingLinea.fromJson(x))) : [],
  );

  Map<String, dynamic> toJson() => {
    "pickId": pickId,
    "numeroDocumento": numeroDocumento,
    "serie": serie,
    "transaccionId": transaccionId,
    "transaccion": transaccion,
    "tipo": tipo,
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
    "lineas": List<dynamic>.from(lineas!.map((x) => x.toJson())),
  };

  OrdenPicking.empty() {
    pickId = 0;
    numeroDocumento = 0;
    serie = '';
    transaccionId = 0;
    transaccion = '';
    tipo = '';
    movimientoId = 0;
    fechaDate = DateTime.now();
    fechaDocumento = DateTime.now();
    estado = '';
    almacenIdOrigen = 0;
    almacenIdDestino = 0;
    prioridad = '';
    comentario = '';
    cantLineas = 0;
    tInfoEmpresaWsId = 0;
    usuId = 0;
    entidadId = 0;
    codEntidad = '';
    ruc = '';
    nombre = '';
    telefono = '';
    localidad = '';
    lineas = [];
  }
}

class PickingLinea {
  late int pickLineaId;
  late int pickId;
  late int lineaId;
  late int itemId;
  late int cantidadPedida;
  late int cantidadPickeada;
  late int tipoLineaAdicional;
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
    tipoLineaAdicional: json["tipoLineaAdicional"] as int? ?? 0,
    lineaIdOriginal: json["lineaIdOriginal"] as int? ?? 0,
    codItem: json["codItem"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    ubicaciones: json["ubicaciones"] != null ? List<UbicacionePicking>.from(json["ubicaciones"].map((x) => UbicacionePicking.fromJson(x))) : [],
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
    tipoLineaAdicional = 0;
    lineaIdOriginal = 0;
    codItem = '';
    descripcion = '';
    ubicaciones = [];
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
    itemAlmacenUbicacionId: json["ItemAlmacenUbicacionId"] as int? ?? 0,
    itemId: json["ItemId"] as int? ?? 0,
    almacenUbicacionId: json["AlmacenUbicacionId"] as int? ?? 0,
    existenciaActual: json["ExistenciaActual"] as int? ?? 0,
    existenciaMaxima: json["ExistenciaMaxima"] as int? ?? 0,
    existenciaMinima: json["ExistenciaMinima"] as int? ?? 0,
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
    "fechaBaja": fechaBaja,
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
}
