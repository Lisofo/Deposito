// To parse this JSON data, do
//
//     final pedido = pedidoFromJson(jsonString);

import 'dart:convert';

List<Pedido> pedidoFromJson(String str) => List<Pedido>.from(json.decode(str).map((x) => Pedido.fromJson(x)));

String pedidoToJson(List<Pedido> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Pedido {
  late int ordenTrabajoId;
  late String numeroOrdenTrabajo;
  late DateTime? fechaOrdenTrabajo;
  late String descripcion;
  late int transaccionId;
  late int clienteId;
  late String codCliente;
  late String ruc;
  late String nombre;
  late int monedaId;
  late String codMoneda;
  late String descMoneda;
  late String signo;
  late int totalOrdenTrabajo;
  late String comentarioCliente;
  late String comentarioTrabajo;
  late String estado;
  late int presupuestoIdPlantilla;
  late String numeroPresupuesto;
  late String descripcionPresupuesto;
  late double totalPresupuesto;
  late DateTime? fechaVencimiento;
  late DateTime? fechaEntrega;
  late bool plantilla;
  late int unidadId;
  late int? km;
  late String servicio;
  late String central;
  late bool credito;

  Pedido({
    required this.ordenTrabajoId,
    required this.numeroOrdenTrabajo,
    required this.fechaOrdenTrabajo,
    required this.descripcion,
    required this.transaccionId,
    required this.clienteId,
    required this.codCliente,
    required this.ruc,
    required this.nombre,
    required this.monedaId,
    required this.codMoneda,
    required this.descMoneda,
    required this.signo,
    required this.totalOrdenTrabajo,
    required this.comentarioCliente,
    required this.comentarioTrabajo,
    required this.estado,
    required this.presupuestoIdPlantilla,
    required this.numeroPresupuesto,
    required this.descripcionPresupuesto,
    required this.totalPresupuesto,
    required this.fechaVencimiento,
    required this.fechaEntrega,
    required this.plantilla,
    required this.unidadId,
    required this.km,
    required this.servicio,
    required this.central,
    required this.credito,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
    ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
    numeroOrdenTrabajo: json["numeroOrdenTrabajo"] as String? ?? '',
    fechaOrdenTrabajo: json["fechaOrdenTrabajo"] != null ? DateTime.parse(json["fechaOrdenTrabajo"]) : null,
    descripcion: json["descripcion"] as String? ?? '',
    transaccionId: json["transaccionId"] as int? ?? 0,
    clienteId: json["clienteId"] as int? ?? 0,
    codCliente: json["codCliente"] as String? ?? '',
    ruc: json["ruc"] as String? ?? '',
    nombre: json["nombre"] as String? ?? '',
    monedaId: json["monedaId"] as int? ?? 0,
    codMoneda: json["codMoneda"] as String? ?? '',
    descMoneda: json["descMoneda"] as String? ?? '',
    signo: json["signo"] as String? ?? '',
    totalOrdenTrabajo: json["totalOrdenTrabajo"] as int? ?? 0,
    comentarioCliente: json["comentarioCliente"] as String? ?? '',
    comentarioTrabajo: json["comentarioTrabajo"] as String? ?? '',
    estado: json["estado"] as String? ?? '',
    presupuestoIdPlantilla: json["presupuestoIdPlantilla"] as int? ?? 0,
    numeroPresupuesto: json["numeroPresupuesto"] as String? ?? '',
    descripcionPresupuesto: json["descripcionPresupuesto"] as String? ?? '',
    totalPresupuesto: json["totalPresupuesto"] as double? ?? 0.0,
    fechaVencimiento: json["fechaVencimiento"] != null ? DateTime.parse(json["fechaVencimiento"]) : null,
    fechaEntrega: json["fechaEntrega"] != null ? DateTime.parse(json["fechaEntrega"]) : null,
    plantilla: json["plantilla"] as bool? ?? false,
    unidadId: json["unidadId"] as int? ?? 0,
    km: json["km"],
    servicio: json["servicio"] as String? ?? '',
    central: json["central"] as String? ?? '',
    credito: json["credito"] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    "ordenTrabajoId": ordenTrabajoId,
    "numeroOrdenTrabajo": numeroOrdenTrabajo,
    "fechaOrdenTrabajo": fechaOrdenTrabajo?.toIso8601String(),
    "descripcion": descripcion,
    "transaccionId": transaccionId,
    "clienteId": clienteId,
    "codCliente": codCliente,
    "ruc": ruc,
    "nombre": nombre,
    "monedaId": monedaId,
    "codMoneda": codMoneda,
    "descMoneda": descMoneda,
    "signo": signo,
    "totalOrdenTrabajo": totalOrdenTrabajo,
    "comentarioCliente": comentarioCliente,
    "comentarioTrabajo": comentarioTrabajo,
    "estado": estado,
    "presupuestoIdPlantilla": presupuestoIdPlantilla,
    "numeroPresupuesto": numeroPresupuesto,
    "descripcionPresupuesto": descripcionPresupuesto,
    "totalPresupuesto": totalPresupuesto,
    "fechaVencimiento": fechaVencimiento?.toIso8601String(),
    "fechaEntrega": fechaEntrega?.toIso8601String(),
    "plantilla": plantilla,
    "unidadId": unidadId,
    "km": km,
    "servicio": servicio,
    "central": central,
    "credito": credito,
  };

  Pedido.empty(){
    ordenTrabajoId = 0;
    numeroOrdenTrabajo = '';
    fechaOrdenTrabajo = null;
    descripcion = '';
    transaccionId = 0;
    clienteId = 0;
    codCliente = '';
    ruc = '';
    nombre = '';
    monedaId = 0;
    codMoneda = '';
    descMoneda = '';
    signo = '';
    totalOrdenTrabajo = 0;
    comentarioCliente = '';
    comentarioTrabajo = '';
    estado = '';
    presupuestoIdPlantilla = 0;
    numeroPresupuesto = '';
    descripcionPresupuesto = '';
    totalPresupuesto = 0.0;
    fechaVencimiento = null;
    fechaEntrega = null;
    plantilla = false;
    unidadId = 0;
    km = null;
    servicio = '';
    central = '';
    credito = false;
  }
}