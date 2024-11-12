import 'package:deposito/models/client.dart';
import 'package:deposito/models/linea.dart';
import 'package:deposito/models/pedido.dart';
import 'package:deposito/models/product.dart';
import 'package:flutter/material.dart';

class ProductProvider with ChangeNotifier {
  // Variables privadas con sus respectivos getters
  String _item = '';
  String get item => _item;

  String _query = '';
  String get query => _query;

  int _vendedorId = 0;
  int get vendedorId => _vendedorId;

  int _imageIndex = 0;
  int get imageIndex => _imageIndex;

  Product _product = Product.empty();
  Product get product => _product;

  Client _client = Client.empty();
  Client get client => _client;

  String _almacen = '';
  String get almacen => _almacen;

  String _mismoColor = '';
  String get mismoColor => _mismoColor;

  String _token = '';
  String get token => _token;

  String _token2 = '';
  String get token2 => _token2;

  Pedido _pedido = Pedido.empty();
  Pedido get pedido => _pedido;

  List<Linea> _lineas = [];
  List<Linea> get lineas => _lineas;
  
  List<Linea> _lineasGenericas = [];
  List<Linea> get lineasGenericas => _lineasGenericas;

  String _raiz = '';
  String get raiz => _raiz;
  
  String _almacenNombre = '';
  String get almacenNombre => _almacenNombre;
  
  int _rptGenId = 0;
  int get rptGenId => _rptGenId;

  // Métodos para actualizar las variables y notificar cambios

  void setRptId(int rptGenId){
    _rptGenId = rptGenId;
    notifyListeners();
  }

  void setRaiz(String raiz) {
    _raiz = raiz;
    notifyListeners();
  }
  
  void setLineasGenericas(List<Linea> lines) {
    _lineasGenericas = lines;
    notifyListeners();
  }

  void addLinea(Linea line){
    _lineasGenericas.add(line);
    notifyListeners();
  }
  
  void removeLinea(Linea line){
    _lineasGenericas.remove(line);
    notifyListeners();
  }

  void setLineas(List<Linea> lines) {
    _lineas = lines;
    notifyListeners();
  }

  void setVendedorId(int seller) {
    _vendedorId = seller;
    notifyListeners();
  }

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void setItem(String codigo) {
    _item = codigo;
    notifyListeners();
  }

  void setImageIndex(int index) {
    _imageIndex = index;
    notifyListeners();
  }

  void setProduct(Product prod) {
    _product = prod;
    notifyListeners();
  }

  void setClient(Client cliente) {
    _client = cliente;
    notifyListeners();
  }

  void setAlmacen(String codAlmacen) {
    _almacen = codAlmacen;
    notifyListeners();
  }

  void setAlmacenNombre(String almacen) {
    _almacenNombre = almacen;
    notifyListeners();
  }

  void setColor(String color) {
    _mismoColor = color;
    notifyListeners();
  }

  void setToken(String tok) {
    _token = tok;
    notifyListeners();
  }

  void setToken2(String tok) {
    _token2 = tok;
    notifyListeners();
  }

  void setPedido(Pedido pedid) {
    _pedido = pedid;
    notifyListeners();
  }
}