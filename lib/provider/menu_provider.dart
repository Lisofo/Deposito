import 'dart:convert';
import 'package:deposito/services/menu_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class MenuProvider with ChangeNotifier {
  List<dynamic> opciones = [];
  List<dynamic> opcionesRevision = [];
  List<String> _quickAccessItems = [];
  bool _isDataReady = false;

  MenuProvider() {
    _loadQuickAccess();
  }

  Future<void> initialize(BuildContext context, String token) async {
    await cargarData(context, token);
    _isDataReady = true;
    notifyListeners();
  }

  Future<void> _loadQuickAccess() async {
    final prefs = await SharedPreferences.getInstance();
    _quickAccessItems = prefs.getStringList('quick_access') ?? [];
    notifyListeners();
  }

  Future<void> _saveQuickAccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('quick_access', _quickAccessItems);
  }

  List<String> get quickAccessItems => _quickAccessItems;
  bool get isDataReady => _isDataReady;

  Future<void> addQuickAccess(String route) async {
    if (!_quickAccessItems.contains(route)/* && _quickAccessItems.length < 6*/) {
      _quickAccessItems.add(route);
      await _saveQuickAccess();
      notifyListeners();
    }
  }

  Future<void> removeQuickAccess(String route) async {
    _quickAccessItems.remove(route);
    await _saveQuickAccess();
    notifyListeners();
  }

  bool isQuickAccess(String route) => _quickAccessItems.contains(route);

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