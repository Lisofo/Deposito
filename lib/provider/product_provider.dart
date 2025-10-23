// product_provider.dart (cambios completos)

import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/client.dart';
import 'package:deposito/models/entrega.dart';
import 'package:deposito/models/linea.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/models/pedido.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/models/producto_deposito.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/models/ubicacion_picking.dart';
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

  ProductoDeposito _productoDeposito = ProductoDeposito.empty();
  ProductoDeposito get productoDeposito => _productoDeposito;

  Client _client = Client.empty();
  Client get client => _client;

  Almacen _almacen = Almacen.empty();
  Almacen get almacen => _almacen;

  Almacene _almacene = Almacene.empty();
  Almacene get almacene => _almacene;

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

  List _fotos = [];
  List get fotos => _fotos;

  int _uId = 0;
  int get uId => _uId;

  UbicacionAlmacen _ubicacion = UbicacionAlmacen.empty();
  UbicacionAlmacen get ubicacion => _ubicacion;

  List<String> _permisos = [];
  List<String> get permisos => _permisos;

  int _usuarioConteo = 0;
  int get usuarioConteo => _usuarioConteo;

  String _name = '';
  String get name => _name;

  OrdenPicking _ordenPicking = OrdenPicking.empty();
  OrdenPicking get ordenPicking => _ordenPicking;
  
  OrdenPicking _ordenPickingInterna = OrdenPicking.empty();
  OrdenPicking get ordenPickingInterna => _ordenPickingInterna;

  UbicacionePicking? _ubicacionSeleccionada;
  UbicacionePicking? get ubicacionSeleccionada => _ubicacionSeleccionada;

  int _currentLineIndex = 0;
  int get currentLineIndex => _currentLineIndex;

  List<PickingLinea> _lineasPicking = [];
  List<PickingLinea> get lineasPicking => _lineasPicking;

  String _menu = '';
  String get menu => _menu;

  bool _modoSeleccionUbicacion = true;
  bool get modoSeleccionUbicacion => _modoSeleccionUbicacion;

  String _menuTitle = '';
  String get menuTitle => _menuTitle;

  bool _camDisponible = true;
  bool get camera => _camDisponible;

  List<UbicacionAlmacen> _listaDeUbicacionesXAlmacen = [];
  List<UbicacionAlmacen> get listaDeUbicacionesXAlmacen => _listaDeUbicacionesXAlmacen;

  List<OrdenPicking> _ordenesExpedicion = [];
  List<OrdenPicking> get ordenesExpedicion => _ordenesExpedicion;

  Entrega _entrega = Entrega.empty();
  Entrega get entrega => _entrega;

  bool _vistaMonitor = false;
  bool get vistaMonitor => _vistaMonitor;

  final Map<int, List<UbicacionPicking>> _ubicacionesPicking = {};
  Map<int, List<UbicacionPicking>> get ubicacionesPicking => _ubicacionesPicking;

  bool _voyDesdeMenu = false;
  bool get voyDesdeMenu => _voyDesdeMenu;

  bool _filtroMostrador = false;
  bool get filtroMostrador => _filtroMostrador;

  void setFiltroMostrador(bool value) {
    _filtroMostrador = value;
    notifyListeners();
  }

  void setVoyDesdeMenu(bool desdeMenu) {
    _voyDesdeMenu = desdeMenu;
    notifyListeners();
  }

  void agregarUbicacionPicking(int lineaId, UbicacionPicking ubicacion) {
    if (!_ubicacionesPicking.containsKey(lineaId)) {
      _ubicacionesPicking[lineaId] = [];
    }
    _ubicacionesPicking[lineaId]!.add(ubicacion);
    notifyListeners();
  }

  void limpiarUbicacionesPicking() {
    _ubicacionesPicking.clear();
    notifyListeners();
  }

  void actualizarUbicacionPicking(int lineaId, List<UbicacionPicking> ubicaciones) {
    _ubicacionesPicking[lineaId] = ubicaciones;
    notifyListeners();
  }

  void setVistaMonitor (bool vista) {
    _vistaMonitor = vista;
    notifyListeners();
  }

  void setEntrega (Entrega entrega) {
    _entrega = entrega;
    notifyListeners();
  }

  void setOrdenesExpedicion (List<OrdenPicking> ordenes) {
    _ordenesExpedicion = ordenes;
    notifyListeners();
  }

  void setListaDeUbicaciones (List<UbicacionAlmacen> lista) {
    _listaDeUbicacionesXAlmacen = lista;
    notifyListeners();
  } 

  void setCamara (bool camera) {
    _camDisponible = camera;
    notifyListeners();
  }

  void setTitle(String title) {
    _menuTitle = title;
    notifyListeners();
  }

  void setModoSeleccionUbicacion(bool modo) {
    _modoSeleccionUbicacion = modo;
    notifyListeners();
  }

  void setMenu(String menu) {
    _menu = menu;
    notifyListeners();
  }

  void setLineasPicking(List<PickingLinea> lineas) {
    _lineasPicking = List.from(lineas);
    notifyListeners();
  }

  void updateLineaPicking(int index, PickingLinea linea) {
    if (index >= 0 && index < _lineasPicking.length) {
      _lineasPicking[index] = linea;
      notifyListeners();
    }
  }

  void resetLineasPicking() {
    _lineasPicking = [];
    notifyListeners();
  }

  void setCurrentLineIndex(int index) {
    _currentLineIndex = index;
    notifyListeners();
  }
  
  void resetCurrentLineIndex() {
    _currentLineIndex = 0;
    notifyListeners();
  }

  void setUbicacionSeleccionada(UbicacionePicking ubicacion) {
    _ubicacionSeleccionada = ubicacion;
    notifyListeners();
  }

  void clearUbicacionSeleccionada() {
    _ubicacionSeleccionada = null;
    notifyListeners();
  }

  void setOrdenPicking(OrdenPicking order) {
    _ordenPicking = order;
    notifyListeners();
  }

  void setOrdenPickingInterna(OrdenPicking order) {
    _ordenPickingInterna = order;
    notifyListeners();
  }

  void setUsuarioConteo(int userId) {
    _usuarioConteo = userId;
    notifyListeners();
  }

  void setPermisos(List<String> permi) {
    _permisos = permi;
    notifyListeners();
  }

  void setUbicacion(UbicacionAlmacen ubi) {
    _ubicacion = ubi;
    notifyListeners();
  }

  void setRptId(int rptGenId) {
    _rptGenId = rptGenId;
    notifyListeners();
  }

  void setFotos(List urls) {
    _fotos = urls;
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

  void addLinea(Linea line) {
    _lineasGenericas.add(line);
    notifyListeners();
  }
  
  void removeLinea(Linea line) {
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

  void setProductoDeposito(ProductoDeposito prod) {
    _productoDeposito = prod;
    notifyListeners();
  }

  void setClient(Client cliente) {
    _client = cliente;
    notifyListeners();
  }

  void setAlmacen(Almacen codAlmacen) {
    _almacen = codAlmacen;
    notifyListeners();
  }

  void setAlmacenUbicacion(Almacene codAlmacen) {
    _almacene = codAlmacen;
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

  void setUsuarioId(int id) {
    _uId = id;
    notifyListeners();
  }

  void setUsuarioName(String name) {
    _name = name;
    notifyListeners();
  }
}