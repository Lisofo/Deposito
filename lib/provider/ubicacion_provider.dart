import 'package:deposito/models/producto_deposito.dart';
import 'package:flutter/material.dart';
import 'package:deposito/models/items_x_ubicacion.dart';

class UbicacionProvider with ChangeNotifier {
  List<Ubicacione> _ubicaciones = [];
  List<ItemsPorUbicacion> _itemsXUbicacionesAlmacen = [];

  List<Ubicacione> get ubicaciones => _ubicaciones;
  List<ItemsPorUbicacion> get itemsXUbicacionesAlmacen => _itemsXUbicacionesAlmacen;

  void setUbicaciones(List<Ubicacione> nuevasUbicaciones) {
    _ubicaciones = nuevasUbicaciones;
    notifyListeners();
  }

  void setItemsXUbicacionesAlmacen(List<ItemsPorUbicacion> nuevosItems) {
    _itemsXUbicacionesAlmacen = nuevosItems;
    notifyListeners();
  }

  void agregarUbicacion(Ubicacione nuevaUbicacion) {
    _ubicaciones.add(nuevaUbicacion);
    notifyListeners();
  }

  void agregarItemXUbicacion(ItemsPorUbicacion nuevoItem) {
    _itemsXUbicacionesAlmacen.add(nuevoItem);
    notifyListeners();
  }
}