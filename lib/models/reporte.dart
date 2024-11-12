// To parse this JSON data, do
//
//     final reporte = reporteFromMap(jsonString);

import 'dart:convert';

Reporte reporteFromMap(String str) => Reporte.fromJson(json.decode(str));

String reporteToMap(Reporte data) => json.encode(data.toMap());

class Reporte {
  late int rptGenId;
  late DateTime fechaEmision;
  late int informeId;
  late String tipo;
  late String informe;
  late int almacenid;
  late String tipoImpresion;
  late String archivo;
  late dynamic destFileName;
  late String generado;
  late dynamic impreso;
  late String p1;
  late String p2;
  late String p3;
  late String p4;
  late String p5;
  late String nombre;
  late String codInforme;
  late int destino;
  late dynamic destImpresora;
  late String archivoUrl;

  Reporte({
    required this.rptGenId,
    required this.fechaEmision,
    required this.informeId,
    required this.tipo,
    required this.informe,
    required this.almacenid,
    required this.tipoImpresion,
    required this.archivo,
    required this.destFileName,
    required this.generado,
    required this.impreso,
    required this.p1,
    required this.p2,
    required this.p3,
    required this.p4,
    required this.p5,
    required this.nombre,
    required this.codInforme,
    required this.destino,
    required this.destImpresora,
    required this.archivoUrl,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) => Reporte(
    rptGenId: json["rptGenId"] as int? ?? 0,
    fechaEmision: DateTime.parse(json["fechaEmision"]),
    informeId: json["informeId"] as int? ?? 0,
    tipo: json["tipo"] as String? ?? '',
    informe: json["informe"] as String? ?? '',
    almacenid: json["almacenid"] as int? ?? 0,
    tipoImpresion: json["tipoImpresion"] as String? ?? '',
    archivo: json["archivo"] as String? ?? '',
    destFileName: json["destFileName"],
    generado: json["generado"] as String? ?? '',
    impreso: json["impreso"],
    p1: json["p1"] as String? ?? '',
    p2: json["p2"] as String? ?? '',
    p3: json["p3"] as String? ?? '',
    p4: json["p4"] as String? ?? '',
    p5: json["p5"] as String? ?? '',
    nombre: json["nombre"] as String? ?? '',
    codInforme: json["codInforme"] as String? ?? '',
    destino: json["destino"] as int? ?? 0,
    destImpresora: json["destImpresora"],
    archivoUrl: json["archivoUrl"] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    "rptGenId": rptGenId,
    "fechaEmision": fechaEmision.toIso8601String(),
    "informeId": informeId,
    "tipo": tipo,
    "informe": informe,
    "almacenid": almacenid,
    "tipoImpresion": tipoImpresion,
    "archivo": archivo,
    "destFileName": destFileName,
    "generado": generado,
    "impreso": impreso,
    "p1": p1,
    "p2": p2,
    "p3": p3,
    "p4": p4,
    "p5": p5,
    "nombre": nombre,
    "codInforme": codInforme,
    "destino": destino,
    "destImpresora": destImpresora,
    "archivoUrl": archivoUrl,
  };

  Reporte.empty(){
    rptGenId = 0;
    fechaEmision = DateTime.now();
    informeId = 0;
    tipo = '';
    informe = '';
    almacenid = 0;
    tipoImpresion = '';
    archivo = '';
    destFileName = null;
    generado = '';
    impreso = null;
    p1 = '';
    p2 = '';
    p3 = '';
    p4 = '';
    p5 = '';
    nombre = '';
    codInforme = '';
    destino = 0;
    destImpresora = null;
    archivoUrl = '';
  }
}
