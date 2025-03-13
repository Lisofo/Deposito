// To parse this JSON data, do
//
//     final menu = menuFromJson(jsonString);

import 'dart:convert';

Menu menuFromJson(String str) => Menu.fromJson(json.decode(str));

String menuToJson(Menu data) => json.encode(data.toJson());

class Menu {
  late String nombreApp;
  late List<Ruta> rutas;

  Menu({
    required this.nombreApp,
    required this.rutas,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
    nombreApp: json["nombreApp"],
    rutas: List<Ruta>.from(json["rutas"].map((x) => Ruta.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "nombreApp": nombreApp,
    "rutas": List<dynamic>.from(rutas.map((x) => x.toJson())),
  };

  Menu.empty(){
    nombreApp = '';
    rutas = [];
  }
}

class Ruta {
  late String camino;
  late List<Opcion> opciones;

  Ruta({
    required this.camino,
    required this.opciones,
  });

  factory Ruta.fromJson(Map<String, dynamic> json) => Ruta(
    camino: json["camino"],
    opciones: List<Opcion>.from(json["opciones"].map((x) => Opcion.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "camino": camino,
    "opciones": List<dynamic>.from(opciones.map((x) => x.toJson())),
  };

  Ruta.empty(){
    camino = '';
    opciones = [];
  }
}

class Opcion {
  late String ruta;
  late String icon;
  late String texto;

  Opcion({
    required this.ruta,
    required this.icon,
    required this.texto,
  });

  factory Opcion.fromJson(Map<String, dynamic> json) => Opcion(
    ruta: json["ruta"],
    icon: json["icon"],
    texto: json["texto"],
  );

  Map<String, dynamic> toJson() => {
    "ruta": ruta,
    "icon": icon,
    "texto": texto,
  };

  Opcion.empty(){
    ruta = '';
    icon = '';
    texto = '';
  }
}
