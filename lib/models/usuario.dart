// To parse this JSON data, do
//
//     final usuario = usuarioFromJson(jsonString);

import 'dart:convert';

List<Usuario> usuarioFromJson(String str) => List<Usuario>.from(json.decode(str).map((x) => Usuario.fromJson(x)));

String usuarioToJson(List<Usuario> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Usuario {
  late int usuarioId;
  late String login;
  late String nombre;
  late String? apellido;
  late String? direccion;
  late String? telefono;

  Usuario({
    required this.usuarioId,
    required this.login,
    required this.nombre,
    required this.apellido,
    required this.direccion,
    required this.telefono,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    usuarioId: json["usuarioId"] as int? ?? 0,
    login: json["login"] as String? ?? '',
    nombre: json["nombre"] as String? ?? '',
    apellido: json["apellido"] as String? ?? '',
    direccion: json["direccion"] as String? ?? '',
    telefono: json["telefono"] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    "usuarioId": usuarioId,
    "login": login,
    "nombre": nombre,
    "apellido": apellido,
    "direccion": direccion,
    "telefono": telefono,
  };

  Usuario.empty() {
    usuarioId = 0;
    login = '';
    nombre = '';
    apellido = '';
    direccion = '';
    telefono = '';
  }

  @override
  String toString() => nombre;
}
