import 'dart:convert';
import 'package:deposito/provider/menu_provider.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deposito/config/config_env.dart';


class LoginServices {
  int? statusCode;
  late String apiUrl = ConfigEnv.APIURL;
  late String apiLink = '$apiUrl/api/auth/login-pin';
  var dio = Dio();

  Future<void> login(String login, password, BuildContext context) async {
    var headers = {'Content-Type': 'application/json'};
    var data = json.encode({"login": login, "pin2": password});
    String link = apiLink;
    try {
      var response = await dio.request(
        link,
        options:  Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      statusCode = 1;

      if (statusCode == 1) {
        print(response.data['token']);
        print(response.data['nombre']);
        Provider.of<ProductProvider>(context, listen: false).setToken(response.data['token']);
        Provider.of<ProductProvider>(context, listen: false).setUsuarioId(response.data['uid']);
        Provider.of<MenuProvider>(context, listen: false).setUsuarioId(response.data['uid']);
        Provider.of<ProductProvider>(context, listen: false).setUsuarioName(response.data['nombre']);
      } else { 
        print(response.statusMessage);
      }
    } catch (e) {
      statusCode = 0;
      print('Error: $e');
    }
  }

  Future pin2(String password, BuildContext context) async {
    var headers = {'Content-Type': 'application/json'};
    var data = json.encode({"pin2": password});
    String link = '$apiUrl/api/auth/pin';
    try {
      var resp = await dio.request(
        link,
        options:  Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      statusCode = 1;

      if (statusCode == 1) {
        print(resp.data['token']);
        print(resp.data['nombre']);
      } else { 
        print(resp.statusMessage);
      }
      return resp.data;
    } catch (e) {
      statusCode = 0;
      print('Error: $e');
      return '';
    }
  }

  Future<int?> getStatusCode() async {
    return statusCode;
  }

  Future<void> resetStatusCode () async {
    statusCode = null;
  }

  Future<List<String>> getPermisos(BuildContext context, String token) async {
    String link = '$apiUrl/api/auth/permisos';
    List<String> permisos = [];
  
    try {
      var headers = {'Authorization': token};
      var resp = await dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
  
      if (resp.statusCode == 200) {
        print(resp.data.runtimeType); // Ver qué tipo de datos devuelve la API
  
        if (resp.data is List) {
          permisos = (resp.data as List).map((e) => e.toString()).toList();
        } else if (resp.data is Map && resp.data.containsKey('permisos')) {
          permisos = (resp.data['permisos'] as List).map((e) => e.toString()).toList();
        }
  
        print(permisos);
        return permisos;
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if (e.response!.statusCode == 403) {
              Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            } else if (e.response!.statusCode! >= 500) {
              Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else {
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
    }
  
    return permisos;
  }

}