import 'dart:convert';
import 'package:deposito/provider/product_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deposito/config/config.dart';


class LoginServices {
  int? statusCode;
  late String apiUrl = Config.APIURL;
  late String apiLink = '$apiUrl/api/auth/login-pin';

  Future<void> login(String login, password, BuildContext context) async {
    var headers = {'Content-Type': 'application/json'};
    var data = json.encode({"login": login, "pin2": password});
    var dio = Dio();
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
        print(response.data['vendedorId']);
        Provider.of<ProductProvider>(context, listen: false).setToken(response.data['token']);
        // Provider.of<ProductProvider>(context, listen: false).setVendedorId(response.data['vendedorId'] ?? 0);
      } else { 
        print(response.statusMessage);
      }
    } catch (e) {
      statusCode = 0;
      print('Error: $e');
    }
  }

  Future<int?> getStatusCode() async {
    return statusCode;
  }
}