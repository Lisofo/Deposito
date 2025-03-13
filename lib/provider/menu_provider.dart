import 'dart:convert';

import 'package:deposito/services/menu_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class MenuProvider with ChangeNotifier {
  List<dynamic> opciones = [];
  List<dynamic> opcionesRevision = [];

  MenuProvider();

  Future<List<dynamic>> cargarData(BuildContext context, String token) async {
  final menu = await MenuServices().getMenu(context, token);
  if (menu != null) {
    opciones = menu.rutas;
    return opciones;
  } else {
    return [];
  }
}

  Future<List<dynamic>> cargarMenuRevision(String codTipoOrden) async {
    final resp = await rootBundle.loadString('data/menu_revision.json');

    Map dataMap = json.decode(resp);
    opcionesRevision = dataMap['rutas'];
    return opcionesRevision.where((menu) => menu['tipoOrden'].toString().contains(codTipoOrden)).toList();
  }

  String _menu = '';
  String get menu => _menu;

  void setPage(String codPages) {
    _menu = codPages;
    notifyListeners();
  }
}

final menuProvider = MenuProvider();
