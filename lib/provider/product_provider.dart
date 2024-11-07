import 'package:flutter/material.dart';

class ProductProvider with ChangeNotifier {
  String _producto = '';
  String get producto => _producto;

  String _token = '';
  String get token => _token;

  int _vendedorId = 0;
  int get vendedorId => _vendedorId;

  void setProducto (String product) {
    _producto = product;
    notifyListeners();
  }

  String getProduct(){
    return producto;
  }

  void setToken(String tok) {
    _token = tok;
    notifyListeners();
  }

  void setVendedorId(int seller) {
    _vendedorId = seller;
    notifyListeners();
  }
}