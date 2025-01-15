import 'package:deposito/config/config.dart';
import 'package:deposito/models/producto_deposito.dart';
import 'package:deposito/models/producto_variante.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// import 'package:showroom_maqueta/offline/boxes.dart';
// almancenId 1 = nyp
// almancenId 18 = ufo
import '../models/product.dart';

class ProductServices {
  final _dio = Dio();
  late String apirUrl = Config.APIURL;
  
  Future<List<Product>> getProductByName(BuildContext context, String condicion, String codTipoLista, String almacenId, String codBarra, String offset, String token) async {
    String link = apirUrl += '/api/v1/itemsRaiz/?limit=20&offset=$offset&almacenId=$almacenId&codTipoLista=$codTipoLista';
    if (condicion != '') {
      link += '&condicion=$condicion';
    }
    if (codBarra != '') {     
      link += '&codBarra=$codBarra';
    }
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        )
      );
      
      final List<dynamic> productList = resp.data;
      return productList.map((obj) => Product.fromJson(obj)).toList();
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
             Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              Carteles.showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      }
      return [];
    }
  }

  Future<List<Product>> getProductByVariant(BuildContext context, String raiz, String codAlmacen, String token, String codTipoLista) async {
    String link = apirUrl += '/api/v1/servicios/variantesItem/$raiz?almacenId=$codAlmacen&mismoColor=n&codTipoLista=$codTipoLista';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(link,
        options: Options(
          method: 'GET',
          headers: headers,
        )
      );
      final List<dynamic> productList = resp.data;
      return productList.map((obj) => Product.fromJson(obj)).toList();
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
             Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              Carteles.showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      }
      return [];
    }
  }


  Future<Product> getSingleProductByRaiz(BuildContext context, String raiz, String codAlmacen, String token) async {
    String link = apirUrl +='/api/v1/itemsRaiz/$raiz?almacenId=$codAlmacen';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
          
        ));
      final Product product = Product.fromJson(resp.data);
      return product;
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
             Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              Carteles.showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      }
      return Product.empty();
    }
  }

  //  Future<List> getProductByVariantOffline(String raiz, String codAlmacen) async{
  //   List<dynamic> listProductoRaiz = [];
  //   Product productoSeleccionado = Product.empty();
  //   Product productoTest = Product(codAlmacen: codAlmacen, raiz: raiz, descripcion: 'descripcion', monedaId: 30, memo: 'test', signo: '%', precioVentaActual: 33, precioIvaIncluido: 35, ivaId: 2, valor: 22, disponibleRaiz: 4, existenciaRaiz: 6, variantes: [ProductoVariante(itemId: 333, codItem: 'codigoItem', monedaId: 2, signo: '##', precioVentaActual: 12, precioIvaIncluido: 15, existenciaActual: 2, existenciaTotal: 5, ivaId: 3, valor: 44, codColor: 'codColor', color: 'color', talle: 'talles', disponible: 3, colorHexCode: 255, r: 200, g: 100, b: 150),]);
  //   try{
  //     listProductoRaiz = boxProduct.values.where((producto) => 
  //     (producto.raiz.toUpperCase() == raiz)).toList();

  //     productoSeleccionado = listProductoRaiz[0];
  //     //return productoSeleccionado.variantes;
  //     return productoTest.variantes;
  //   }
  //   catch (e) {
  //     return [];
  //   }
  //  }

  Future<List<Product>> getAllProducts(BuildContext context, String codAlmacen, String token) async {
    String link = apirUrl += '/api/v1/servicios/itemsRaiz/Todos/?almacenId=$codAlmacen';
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(link,
          options: Options(
            method: 'GET',
            headers: headers,
          ));
      final List<dynamic> productList = resp.data;
      return productList.map((obj) => Product.fromJson(obj)).toList();
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
             Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              Carteles.showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      }
      return [];
    }
  }


//   Future<List> getProductByNameOffline(String query) async{
//       List<dynamic> listaRet = [];
//       listaRet = boxProduct.values.where((producto) 
//       => (producto.descripcion.toUpperCase() + ' ' + producto.raiz.toUpperCase()).contains(query.toUpperCase())).toList();
//       return listaRet;

//   }

  

//   Future<List> getProductsByVariantOffline (String scanned) async {
//     List<dynamic> listaRet = [];
//     try{
//       listaRet = boxProduct.values.where((producto) => (producto.variantes.codItem.toUpperCase()).contains(scanned.toUpperCase())).toList();
//       return listaRet;
//     }
//     catch(e){ 
//       return [];
//     }
//   }


// Future<List<dynamic>> getProductsOfflineFinal (String dato)async{
//   List<dynamic>listaProductos = boxProduct.values.toList();
//   List<String> datos = dato.split(' ');
//   for(int i = 0; i< datos.length; i++){
//     listaProductos = busquedaProductosRecursiva(listaProductos, datos[i]);
    
//   }
//   return listaProductos;
// }



List<dynamic> busquedaProductosRecursiva (List<dynamic> lista, String dato){
  dato = dato.toUpperCase();
  lista = lista.where((producto) => producto.raiz.toUpperCase().contains(dato) || producto.descripcion.toUpperCase().contains(dato) || 
  producto.variantes.any((ProductoVariante variante) => variante.codItem.toUpperCase().contains(dato))).toList();
  return lista;
}


// Future<List<dynamic>> getProductsByEverythingOffline(String dato) async {
//   try {
//     final List<dynamic> productos = boxProduct.values.toList();
//     final List<dynamic> matchingProducts = [];

//     // Search for matching products based on description and raiz
//     matchingProducts.addAll(productos.where((producto) =>
//         (producto.descripcion.toUpperCase() + ' ' + producto.raiz.toUpperCase()).contains(dato.toUpperCase())));

//     // If no matches found, search based on talle
//     if (matchingProducts.isEmpty) {
//       matchingProducts.addAll(productos.where((producto) =>
//           producto.variantes.any((ProductoVariante variante) =>
//               variante.codItem.toUpperCase().contains(dato.toUpperCase()))));
//     }

//     return matchingProducts;
//   } catch (e) {
//     print(e);
//     return [];
//   }
// }

Future<ProductoDeposito> getProductoDeposito(BuildContext context, String raiz, String token) async {
    String link = apirUrl += '/api/v1/deposito/?limit=20';
    if (raiz != '') {
      link += '&raiz=$raiz';
    }
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        )
      );
      
      final ProductoDeposito productoDeposito = ProductoDeposito.fromJson(resp.data);
      return productoDeposito;
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
             Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              Carteles.showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      }
      return ProductoDeposito.empty();
    }
  }






}
